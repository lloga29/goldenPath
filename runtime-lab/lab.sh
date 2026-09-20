#!/usr/bin/env bash
# GoldenPath v0.2 disposable Runtime Lab.
#
# This script creates a real kind Kubernetes API, bootstraps Argo CD and
# Gatekeeper, renders the implemented Go paved-road template, builds and pushes
# it to a lab-local registry, reconciles the workload through Argo CD, proves an
# admission denial, captures runtime facts, and verifies teardown.
#
# Evidence tier: ephemeral runtime only. This script never claims production
# validation.

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE_DIR="$ROOT_DIR/service-templates/templates/microservice-golang"

KIND_NODE_IMAGE="${GOLDENPATH_KIND_NODE_IMAGE:-kindest/node:v1.37.0@sha256:a1ed56cfb0e7b93589bdf97c8cd566405a265939e3620fc4f5de89adff580ae5}"
ARGOCD_VERSION="${GOLDENPATH_ARGOCD_VERSION:-v3.5.3}"
GATEKEEPER_CHART_VERSION="${GOLDENPATH_GATEKEEPER_CHART_VERSION:-3.23.1}"
REGISTRY_IMAGE="${GOLDENPATH_REGISTRY_IMAGE:-registry:2.8.3}"
REGISTRY_PORT="${GOLDENPATH_REGISTRY_PORT:-5001}"
WAIT_TIMEOUT_SECONDS="${GOLDENPATH_LAB_TIMEOUT_SECONDS:-420}"
SOURCE_REPOSITORY="${GOLDENPATH_SOURCE_REPOSITORY:-https://github.com/lloga29/goldenPath.git}"
SOURCE_REVISION="${GOLDENPATH_SOURCE_REVISION:-${GITHUB_SHA:-$(git -C "$ROOT_DIR" rev-parse HEAD)}}"

raw_id="${GOLDENPATH_LAB_ID:-local-$(git -C "$ROOT_DIR" rev-parse --short=8 HEAD)-$$}"
LAB_ID="$(printf '%s' "$raw_id" | tr '[:upper:]_' '[:lower:]-' | tr -cd 'a-z0-9-' | cut -c1-32)"
[[ -n "$LAB_ID" ]] || LAB_ID="local-$$"

CLUSTER_NAME="gp-${LAB_ID}"
REGISTRY_NAME="${CLUSTER_NAME}-registry"
WORKLOAD_NAMESPACE="goldenpath-${LAB_ID}"
POLICY_APP="gp-policies-${LAB_ID}"
WORKLOAD_APP="gp-workload-${LAB_ID}"
ARTIFACT_DIR="${GOLDENPATH_LAB_ARTIFACT_DIR:-$ROOT_DIR/runtime-lab-artifacts/${LAB_ID}}"
WORK_DIR="$(mktemp -d)"
GENERATED_ROOT="$WORK_DIR/generated"
GENERATED_SERVICE="$GENERATED_ROOT/goldenpath-runtime"
IMAGE_TAG="localhost:${REGISTRY_PORT}/goldenpath-runtime:${LAB_ID}"

CLEANUP_DONE=0

log() {
    printf '[runtime-lab] %s\n' "$*"
}

fail() {
    printf '[runtime-lab] ERROR: %s\n' "$*" >&2
    return 1
}

require_commands() {
    local command
    for command in docker kind kubectl helm git python3 copier go; do
        command -v "$command" >/dev/null 2>&1 || {
            fail "required command '$command' is not available"
            return 1
        }
    done
}

cluster_exists() {
    kind get clusters 2>/dev/null | grep -Fxq "$CLUSTER_NAME"
}

registry_exists() {
    docker ps -a --format '{{.Names}}' 2>/dev/null | grep -Fxq "$REGISTRY_NAME"
}

cleanup_resources() {
    local status=0

    if cluster_exists; then
        log "Deleting kind cluster $CLUSTER_NAME"
        kind delete cluster --name "$CLUSTER_NAME" >/dev/null || status=1
    fi

    if registry_exists; then
        log "Deleting local registry $REGISTRY_NAME"
        docker rm -f "$REGISTRY_NAME" >/dev/null || status=1
    fi

    if cluster_exists; then
        printf '[runtime-lab] ERROR: cluster residue remains: %s\n' "$CLUSTER_NAME" >&2
        status=1
    fi
    if registry_exists; then
        printf '[runtime-lab] ERROR: registry residue remains: %s\n' "$REGISTRY_NAME" >&2
        status=1
    fi

    return "$status"
}

on_exit() {
    local status=$?
    trap - EXIT
    if [[ "$CLEANUP_DONE" -eq 0 ]]; then
        cleanup_resources || status=1
    fi
    rm -rf "$WORK_DIR"
    exit "$status"
}
trap on_exit EXIT

wait_for_application() {
    local app="$1"
    local deadline=$((SECONDS + WAIT_TIMEOUT_SECONDS))
    local sync=""
    local health=""

    while (( SECONDS < deadline )); do
        sync="$(kubectl -n argocd get application "$app" -o jsonpath='{.status.sync.status}' 2>/dev/null || true)"
        health="$(kubectl -n argocd get application "$app" -o jsonpath='{.status.health.status}' 2>/dev/null || true)"
        if [[ "$sync" == "Synced" && "$health" == "Healthy" ]]; then
            return 0
        fi
        sleep 5
    done

    kubectl -n argocd get application "$app" -o yaml >&2 || true
    fail "Argo CD application '$app' did not become Synced/Healthy within ${WAIT_TIMEOUT_SECONDS}s"
}

create_cluster_and_registry() {
    if cluster_exists || registry_exists; then
        fail "lab identity '$LAB_ID' already has runtime residue; use a different GOLDENPATH_LAB_ID or clean it first"
        return 1
    fi

    log "Starting local OCI registry $REGISTRY_NAME on localhost:$REGISTRY_PORT"
    docker run -d         --restart=always         -p "127.0.0.1:${REGISTRY_PORT}:5000"         --name "$REGISTRY_NAME"         "$REGISTRY_IMAGE" >/dev/null

    log "Creating kind cluster $CLUSTER_NAME with $KIND_NODE_IMAGE"
    kind create cluster         --name "$CLUSTER_NAME"         --config "$ROOT_DIR/runtime-lab/kind-config.yaml"         --image "$KIND_NODE_IMAGE"         --wait "${WAIT_TIMEOUT_SECONDS}s"

    docker network connect kind "$REGISTRY_NAME"

    local node
    while IFS= read -r node; do
        [[ -n "$node" ]] || continue
        docker exec "$node" mkdir -p "/etc/containerd/certs.d/localhost:${REGISTRY_PORT}"
        cat <<EOF | docker exec -i "$node" sh -c "cat > /etc/containerd/certs.d/localhost:${REGISTRY_PORT}/hosts.toml"
server = "http://${REGISTRY_NAME}:5000"

[host."http://${REGISTRY_NAME}:5000"]
  capabilities = ["pull", "resolve", "push"]
EOF
    done < <(kind get nodes --name "$CLUSTER_NAME")

    kubectl create configmap local-registry-hosting         -n kube-public         --from-literal=localRegistryHosting.v1="host: localhost:${REGISTRY_PORT}"         --dry-run=client -o yaml | kubectl apply -f - >/dev/null
}

bootstrap_platform() {
    log "Bootstrapping Gatekeeper chart $GATEKEEPER_CHART_VERSION"
    helm repo add gatekeeper https://open-policy-agent.github.io/gatekeeper/charts --force-update >/dev/null
    helm upgrade --install gatekeeper gatekeeper/gatekeeper         --namespace gatekeeper-system         --create-namespace         --version "$GATEKEEPER_CHART_VERSION"         --wait         --timeout "${WAIT_TIMEOUT_SECONDS}s" >/dev/null

    kubectl wait         --namespace gatekeeper-system         --for=condition=Available         deployment/gatekeeper-controller-manager         --timeout="${WAIT_TIMEOUT_SECONDS}s" >/dev/null

    log "Bootstrapping Argo CD $ARGOCD_VERSION"
    kubectl create namespace argocd >/dev/null
    kubectl apply         --namespace argocd         --server-side         --force-conflicts         -f "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml" >/dev/null

    kubectl wait         --for=condition=Established         crd/applications.argoproj.io         --timeout="${WAIT_TIMEOUT_SECONDS}s" >/dev/null

    kubectl rollout status deployment/argocd-repo-server -n argocd --timeout="${WAIT_TIMEOUT_SECONDS}s" >/dev/null
    kubectl rollout status deployment/argocd-server -n argocd --timeout="${WAIT_TIMEOUT_SECONDS}s" >/dev/null
    kubectl rollout status statefulset/argocd-application-controller -n argocd --timeout="${WAIT_TIMEOUT_SECONDS}s" >/dev/null
}

render_build_and_push_service() {
    mkdir -p "$GENERATED_ROOT"

    log "Rendering the implemented Go paved-road template"
    copier copy --trust --defaults         --data project_name=goldenpath-runtime         --data github_owner=lloga29         --data team=platform         --data description="GoldenPath Runtime Lab reference service"         --data port=8080         --data owner_email=platform@example.com         --data go_version=1.26         "$TEMPLATE_DIR" "$GENERATED_ROOT" >/dev/null

    [[ -f "$GENERATED_SERVICE/Dockerfile" ]] || {
        fail "the paved-road template did not render the expected Dockerfile"
        return 1
    }

    log "Resolving generated Go module dependencies"
    (cd "$GENERATED_SERVICE" && go mod tidy)
    [[ -f "$GENERATED_SERVICE/go.sum" ]] || {
        fail "go mod tidy did not produce the go.sum required by the template Dockerfile"
        return 1
    }

    log "Building generated service image $IMAGE_TAG"
    docker build --pull -t "$IMAGE_TAG" "$GENERATED_SERVICE" >/dev/null

    log "Pushing generated service into the lab-local registry"
    local push_output
    push_output="$(docker push "$IMAGE_TAG" 2>&1)"
    printf '%s\n' "$push_output"

    IMAGE_DIGEST="$(printf '%s\n' "$push_output" | sed -nE 's/.*digest: (sha256:[0-9a-f]{64}).*/\1/p' | tail -n 1)"
    if [[ ! "$IMAGE_DIGEST" =~ ^sha256:[0-9a-f]{64}$ ]]; then
        local repo_digest
        repo_digest="$(docker image inspect "$IMAGE_TAG" --format '{{index .RepoDigests 0}}' 2>/dev/null || true)"
        IMAGE_DIGEST="${repo_digest##*@}"
    fi
    [[ "$IMAGE_DIGEST" =~ ^sha256:[0-9a-f]{64}$ ]] || {
        fail "unable to resolve the pushed OCI manifest digest"
        return 1
    }

    IMAGE_REF="localhost:${REGISTRY_PORT}/goldenpath-runtime@${IMAGE_DIGEST}"
    log "Generated service immutable identity: $IMAGE_REF"
}

create_gitops_handoff() {
    log "Handing policy desired state to Argo CD at revision $SOURCE_REVISION"
    cat <<EOF | kubectl apply -f - >/dev/null
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ${POLICY_APP}
  namespace: argocd
spec:
  project: default
  source:
    repoURL: ${SOURCE_REPOSITORY}
    targetRevision: ${SOURCE_REVISION}
    path: gitops-config/policies
  destination:
    server: https://kubernetes.default.svc
    namespace: gatekeeper-system
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - ServerSideApply=true
      - SkipDryRunOnMissingResource=true
EOF

    wait_for_application "$POLICY_APP"
    kubectl get k8spspprivilegedcontainer.constraints.gatekeeper.sh deny-privileged-containers >/dev/null

    log "Handing workload desired state to Argo CD with exact digest $IMAGE_DIGEST"
    cat <<EOF | kubectl apply -f - >/dev/null
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ${WORKLOAD_APP}
  namespace: argocd
spec:
  project: default
  source:
    repoURL: ${SOURCE_REPOSITORY}
    targetRevision: ${SOURCE_REVISION}
    path: runtime-lab/gitops
    kustomize:
      images:
        - goldenpath-runtime/reference=${IMAGE_REF}
  destination:
    server: https://kubernetes.default.svc
    namespace: ${WORKLOAD_NAMESPACE}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    managedNamespaceMetadata:
      labels:
        environment: ephemeral
        app.kubernetes.io/managed-by: argocd
    syncOptions:
      - CreateNamespace=true
EOF

    wait_for_application "$WORKLOAD_APP"
    kubectl rollout status         deployment/goldenpath-runtime         -n "$WORKLOAD_NAMESPACE"         --timeout="${WAIT_TIMEOUT_SECONDS}s" >/dev/null
}

prove_admission_denial() {
    log "Exercising a server-side privileged-workload denial"
    local denial_file="$WORK_DIR/deny-privileged.yaml"
    cat > "$denial_file" <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: denied-privileged
  namespace: ${WORKLOAD_NAMESPACE}
  labels:
    app.kubernetes.io/name: denied-privileged
    app.kubernetes.io/component: test
    app.kubernetes.io/part-of: goldenpath-runtime-lab
    team: platform
    environment: ephemeral
spec:
  securityContext:
    runAsNonRoot: true
  containers:
    - name: denied
      image: ${IMAGE_REF}
      resources:
        requests:
          cpu: 10m
          memory: 8Mi
        limits:
          cpu: 20m
          memory: 16Mi
      securityContext:
        privileged: true
        allowPrivilegeEscalation: false
EOF

    local output=""
    local deadline=$((SECONDS + 90))
    while (( SECONDS < deadline )); do
        set +e
        output="$(kubectl apply --dry-run=server -f "$denial_file" 2>&1)"
        local status=$?
        set -e

        if [[ "$status" -ne 0 && "$output" == *"deny-privileged-containers"* ]]; then
            ADMISSION_DENIAL="PASS"
            ADMISSION_MESSAGE="$output"
            log "Gatekeeper denial observed"
            return 0
        fi
        sleep 3
    done

    printf '%s\n' "$output" >&2
    fail "expected Gatekeeper denial from deny-privileged-containers was not observed"
}

capture_runtime_facts() {
    local pod
    pod="$(kubectl get pods -n "$WORKLOAD_NAMESPACE" -l app.kubernetes.io/name=goldenpath-runtime -o jsonpath='{.items[0].metadata.name}')"
    [[ -n "$pod" ]] || {
        fail "reference workload pod was not found"
        return 1
    }

    kubectl wait --for=condition=Ready "pod/$pod" -n "$WORKLOAD_NAMESPACE" --timeout="${WAIT_TIMEOUT_SECONDS}s" >/dev/null

    POD_UID="$(kubectl get pod "$pod" -n "$WORKLOAD_NAMESPACE" -o jsonpath='{.metadata.uid}')"
    WORKLOAD_UID="$(kubectl get deployment goldenpath-runtime -n "$WORKLOAD_NAMESPACE" -o jsonpath='{.metadata.uid}')"
    CLUSTER_IDENTITY="$(kubectl get namespace kube-system -o jsonpath='{.metadata.uid}')"
    OBSERVED_IMAGE="$(kubectl get pod "$pod" -n "$WORKLOAD_NAMESPACE" -o jsonpath='{.spec.containers[0].image}')"
    OBSERVED_IMAGE_ID="$(kubectl get pod "$pod" -n "$WORKLOAD_NAMESPACE" -o jsonpath='{.status.containerStatuses[0].imageID}')"
    POD_PHASE="$(kubectl get pod "$pod" -n "$WORKLOAD_NAMESPACE" -o jsonpath='{.status.phase}')"
    NODE_NAME="$(kubectl get pod "$pod" -n "$WORKLOAD_NAMESPACE" -o jsonpath='{.spec.nodeName}')"
    ARGO_SYNC="$(kubectl -n argocd get application "$WORKLOAD_APP" -o jsonpath='{.status.sync.status}')"
    ARGO_HEALTH="$(kubectl -n argocd get application "$WORKLOAD_APP" -o jsonpath='{.status.health.status}')"

    [[ "$OBSERVED_IMAGE" == "$IMAGE_REF" ]] || {
        fail "observed pod spec image '$OBSERVED_IMAGE' does not equal expected digest identity '$IMAGE_REF'"
        return 1
    }
    [[ "$OBSERVED_IMAGE_ID" == *"sha256:"* ]] || {
        fail "container runtime did not report a SHA-256 image identity: '$OBSERVED_IMAGE_ID'"
        return 1
    }

    local runtime_image
    runtime_image="$(docker exec "$NODE_NAME" crictl inspecti "$IMAGE_REF" 2>/dev/null || true)"
    [[ "$runtime_image" == *"$IMAGE_DIGEST"* ]] || {
        fail "container runtime inspection did not bind the workload to expected digest $IMAGE_DIGEST"
        return 1
    }

    RUNTIME_IDENTITY="PASS"
}

write_report() {
    mkdir -p "$ARTIFACT_DIR"
    REPORT_PATH="$ARTIFACT_DIR/runtime-facts.json"
    local observed_at
    observed_at="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"

    SOURCE_REPOSITORY="$SOURCE_REPOSITORY"     SOURCE_REVISION="$SOURCE_REVISION"     LAB_ID="$LAB_ID"     CLUSTER_NAME="$CLUSTER_NAME"     CLUSTER_IDENTITY="$CLUSTER_IDENTITY"     WORKLOAD_NAMESPACE="$WORKLOAD_NAMESPACE"     WORKLOAD_UID="$WORKLOAD_UID"     POD_UID="$POD_UID"     POD_PHASE="$POD_PHASE"     IMAGE_REF="$IMAGE_REF"     IMAGE_DIGEST="$IMAGE_DIGEST"     OBSERVED_IMAGE="$OBSERVED_IMAGE"     OBSERVED_IMAGE_ID="$OBSERVED_IMAGE_ID"     ARGO_SYNC="$ARGO_SYNC"     ARGO_HEALTH="$ARGO_HEALTH"     POLICY_APP="$POLICY_APP"     WORKLOAD_APP="$WORKLOAD_APP"     ADMISSION_DENIAL="$ADMISSION_DENIAL"     RUNTIME_IDENTITY="$RUNTIME_IDENTITY"     OBSERVED_AT="$observed_at"     KIND_NODE_IMAGE="$KIND_NODE_IMAGE"     ARGOCD_VERSION="$ARGOCD_VERSION"     GATEKEEPER_CHART_VERSION="$GATEKEEPER_CHART_VERSION"     python3 - <<'PY' > "$REPORT_PATH"
import json
import os

report = {
    "schemaVersion": "goldenpath.runtime-lab-facts/v1",
    "evidenceTier": "runtime",
    "environmentClass": "ephemeral-lab",
    "productionValidation": "NOT_CLAIMED",
    "observedAt": os.environ["OBSERVED_AT"],
    "execution": {
        "labId": os.environ["LAB_ID"],
        "sourceRepository": os.environ["SOURCE_REPOSITORY"],
        "sourceRevision": os.environ["SOURCE_REVISION"],
    },
    "runtime": {
        "clusterName": os.environ["CLUSTER_NAME"],
        "clusterIdentity": os.environ["CLUSTER_IDENTITY"],
        "namespace": os.environ["WORKLOAD_NAMESPACE"],
        "workloadUid": os.environ["WORKLOAD_UID"],
        "podUid": os.environ["POD_UID"],
        "podPhase": os.environ["POD_PHASE"],
    },
    "artifact": {
        "expectedImage": os.environ["IMAGE_REF"],
        "expectedDigest": os.environ["IMAGE_DIGEST"],
        "observedImage": os.environ["OBSERVED_IMAGE"],
        "observedImageId": os.environ["OBSERVED_IMAGE_ID"],
    },
    "gitops": {
        "policyApplication": os.environ["POLICY_APP"],
        "workloadApplication": os.environ["WORKLOAD_APP"],
        "syncStatus": os.environ["ARGO_SYNC"],
        "healthStatus": os.environ["ARGO_HEALTH"],
    },
    "controls": {
        "admissionPolicyDenial": os.environ["ADMISSION_DENIAL"],
        "runtimeDigestIdentity": os.environ["RUNTIME_IDENTITY"],
        "cleanupResidueCheck": "PASS",
    },
    "dependencies": {
        "kindNodeImage": os.environ["KIND_NODE_IMAGE"],
        "argoCD": os.environ["ARGOCD_VERSION"],
        "gatekeeperChart": os.environ["GATEKEEPER_CHART_VERSION"],
    },
}
print(json.dumps(report, indent=2, sort_keys=True))
PY

    cat "$REPORT_PATH"
    log "Runtime facts written to $REPORT_PATH"
}

run_smoke() {
    require_commands
    create_cluster_and_registry
    bootstrap_platform
    render_build_and_push_service
    create_gitops_handoff
    prove_admission_denial
    capture_runtime_facts

    log "Destroying the Runtime Lab and verifying expected cleanup"
    cleanup_resources
    CLEANUP_DONE=1

    write_report
    log "PASS: reproducible Runtime Lab lifecycle completed with runtime evidence only"
}

case "${1:-smoke}" in
    smoke)
        run_smoke
        ;;
    down)
        require_commands
        cleanup_resources
        CLEANUP_DONE=1
        ;;
    *)
        printf 'Usage: %s [smoke|down]\n' "$0" >&2
        exit 2
        ;;
esac
