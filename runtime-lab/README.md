# GoldenPath Runtime Lab

The Runtime Lab is the supported disposable Kubernetes runtime for GoldenPath v0.2 P1.

The supported smoke lifecycle is:

```bash
./runtime-lab/lab.sh smoke
```

It creates a kind cluster, starts a lab-local OCI registry, bootstraps Gatekeeper and Argo CD, renders the implemented Go paved-road service template, builds and pushes that service, hands policy and workload desired state to Argo CD, waits for reconciliation, proves a privileged workload is denied by Gatekeeper, verifies the running workload identity by SHA-256 digest, captures runtime facts, destroys the cluster and registry, and fails if expected cleanup leaves residue.

## Supported dependency baseline

- kind: v0.33.0
- Kubernetes node image: `kindest/node:v1.37.0@sha256:a1ed56cfb0e7b93589bdf97c8cd566405a265939e3620fc4f5de89adff580ae5`
- Argo CD: v3.5.3
- Gatekeeper chart: 3.23.1
- registry: 2.8.3

The CI workflow installs kind and Helm with pinned checksums. The kind node image is pinned by OCI digest.

## Bootstrap boundary

P1 permits an explicit bootstrap boundary:

1. create the disposable kind cluster and local registry;
2. install Gatekeeper and Argo CD;
3. create Argo CD Application objects that bind the exact repository revision and, for the workload, the exact generated image digest;
4. let Argo CD own steady-state reconciliation of policies and the reference workload.

The dynamic image override is explicit in the Argo CD Application and is captured in the runtime facts. It is not a hidden post-reconciliation mutation.

## Isolation and cleanup

A run receives a unique lab id, cluster name, namespace, Argo CD application names, and registry name. The default local registry port is 5001 and can be overridden with `GOLDENPATH_REGISTRY_PORT`.

The smoke command always attempts cleanup. A successful run additionally verifies that the kind cluster and registry container no longer exist. Cleanup failure is a failed Runtime Lab run, not passing assurance.

## Runtime facts

Successful smoke execution writes `runtime-facts.json` beneath `GOLDENPATH_LAB_ARTIFACT_DIR` or `runtime-lab-artifacts/<lab-id>/`.

The facts include the source revision, ephemeral cluster identity, namespace, workload/pod UIDs, expected and observed image identities, Argo CD sync/health status, admission-denial result, digest-verification result, dependency versions, and cleanup result.

This object is deliberately named `goldenpath.runtime-lab-facts/v1`. P1 does not claim that it is the signed assurance receipt introduced in P2.

## What this proves

A successful run proves, for the identified disposable execution:

- a real Kubernetes API was created;
- the supported bootstrap components became ready;
- repository policies were reconciled by Argo CD;
- a service rendered from the implemented Go paved-road template was built and deployed;
- the reference workload reconciled and became Ready;
- Gatekeeper rejected a privileged workload through server-side admission;
- the running workload was bound to the expected SHA-256 image digest;
- runtime identity and reconciliation facts were observed;
- teardown completed without the expected kind/registry residue.

## What this does not prove

The Runtime Lab does not prove or claim:

- production validation;
- managed-cloud Kubernetes behavior;
- production networking, identity, storage, availability, backup, or disaster recovery;
- organization-specific GitHub, Argo CD, or Kubernetes authorization controls;
- external compliance certification;
- P2 receipt signing or independent cryptographic verification.

Those require separately scoped evidence.
