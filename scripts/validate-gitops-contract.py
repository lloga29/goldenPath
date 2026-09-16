#!/usr/bin/env python3
"""Validate the Golden Path Argo CD platform reconciliation contract."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]
GITOPS = ROOT / "gitops-config"
APPSET_PATH = GITOPS / "argocd/applicationsets/platform-apps.yaml"
RESOURCES_APPSET_PATH = GITOPS / "argocd/applicationsets/platform-resources.yaml"
PROJECT_PATH = GITOPS / "argocd/projects/platform.yaml"
GATEWAY_CLASS_PATH = GITOPS / "platform/resources/gateway-class.yaml"
VALUES_ROOT = GITOPS / "platform/values"
EXPECTED_COMPONENTS = {
    "cert-manager",
    "external-secrets",
    "kube-prometheus-stack",
    "loki",
    "tempo",
    "gatekeeper",
    "envoy-gateway",
}
EXPECTED_ENVIRONMENTS = {
    "dev": {"autoSync": True, "prune": True},
    "staging": {"autoSync": True, "prune": False},
    "prod": {"autoSync": False, "prune": False},
}
GIT_VALUES_REPO = "https://github.com/lloga29/goldenPath.git"
# Accept exact semantic-style chart versions, including a conventional leading
# v and optional prerelease/build suffix. Floating refs such as latest/main are
# therefore rejected by structure rather than by a short denylist.
EXACT_VERSION_RE = re.compile(r"^v?\d+\.\d+\.\d+(?:[-+][0-9A-Za-z][0-9A-Za-z.-]*)?$")


def load_yaml(path: Path) -> dict:
    with path.open(encoding="utf-8") as handle:
        value = yaml.safe_load(handle)
    if not isinstance(value, dict):
        raise ValueError(f"{path.relative_to(ROOT)} must contain one YAML mapping")
    return value


def active_yaml_files() -> list[Path]:
    return sorted(
        path
        for path in GITOPS.rglob("*")
        if path.is_file()
        and path.suffix.lower() in {".yaml", ".yml"}
        and "examples" not in path.parts
    )


def component_and_environment_lists(appset: dict) -> tuple[list[dict], list[dict]]:
    try:
        matrix = appset["spec"]["generators"][0]["matrix"]["generators"]
        components = matrix[0]["list"]["elements"]
        environments = matrix[1]["list"]["elements"]
    except (KeyError, IndexError, TypeError) as exc:
        raise ValueError("platform-apps.yaml does not match the expected matrix generator contract") from exc
    if not isinstance(components, list) or not isinstance(environments, list):
        raise ValueError("platform ApplicationSet component/environment generators must be lists")
    return components, environments


def validate() -> tuple[list[str], list[dict], list[dict]]:
    errors: list[str] = []

    try:
        appset = load_yaml(APPSET_PATH)
        resources_appset = load_yaml(RESOURCES_APPSET_PATH)
        project = load_yaml(PROJECT_PATH)
        gateway_class = load_yaml(GATEWAY_CLASS_PATH)
        components, environments = component_and_environment_lists(appset)
    except (OSError, ValueError, yaml.YAMLError) as exc:
        return [str(exc)], [], []

    # No active Flux desired state or deprecated Kustomize field may survive.
    forbidden_tokens = (
        "helm.toolkit.fluxcd.io",
        "source.toolkit.fluxcd.io",
        "flux-system",
        "commonLabels:",
    )
    for path in active_yaml_files():
        text = path.read_text(encoding="utf-8")
        for token in forbidden_tokens:
            if token in text:
                errors.append(f"{path.relative_to(ROOT)} contains forbidden active token {token!r}")

    names = [item.get("component") for item in components if isinstance(item, dict)]
    if len(names) != len(set(names)):
        errors.append("platform component names must be unique")
    if set(names) != EXPECTED_COMPONENTS:
        errors.append(
            "platform component set mismatch: expected "
            f"{sorted(EXPECTED_COMPONENTS)}, got {sorted(name for name in names if isinstance(name, str))}"
        )
    if "ingress-nginx" in names:
        errors.append("retired ingress-nginx must not be an active platform component")

    project_repos = set(project.get("spec", {}).get("sourceRepos", []))
    if "*" in project_repos:
        errors.append("platform AppProject sourceRepos must remain an explicit allowlist")
    if GIT_VALUES_REPO not in project_repos:
        errors.append(f"platform AppProject must allow the values repository {GIT_VALUES_REPO}")

    for component in components:
        if not isinstance(component, dict):
            errors.append("every platform component generator element must be a mapping")
            continue
        name = component.get("component")
        required = ("component", "release", "chart", "repo", "version", "namespace")
        missing = [key for key in required if not component.get(key)]
        if missing:
            errors.append(f"component {name!r} is missing required fields: {', '.join(missing)}")
            continue
        repo = component["repo"]
        if repo not in project_repos:
            errors.append(f"component {name} repository {repo} is not allowlisted by the platform AppProject")
        version = str(component["version"])
        if not EXACT_VERSION_RE.fullmatch(version):
            errors.append(
                f"component {name} must use an exact semantic-style chart version pin, not {version!r}"
            )
        common_values = VALUES_ROOT / str(name) / "common.yaml"
        if not common_values.is_file():
            errors.append(f"component {name} is missing {common_values.relative_to(ROOT)}")

    env_by_name = {
        item.get("env"): item
        for item in environments
        if isinstance(item, dict) and isinstance(item.get("env"), str)
    }
    if set(env_by_name) != set(EXPECTED_ENVIRONMENTS):
        errors.append(
            f"platform environment set mismatch: expected {sorted(EXPECTED_ENVIRONMENTS)}, got {sorted(env_by_name)}"
        )
    for env, expected in EXPECTED_ENVIRONMENTS.items():
        actual = env_by_name.get(env, {})
        for key, value in expected.items():
            if actual.get(key) is not value:
                errors.append(f"environment {env} must set {key}={value!r}")
        if not actual.get("cluster"):
            errors.append(f"environment {env} must declare a cluster destination")

    sources = appset.get("spec", {}).get("template", {}).get("spec", {}).get("sources", [])
    values_sources = [source for source in sources if isinstance(source, dict) and source.get("ref") == "values"]
    if len(values_sources) != 1 or values_sources[0].get("repoURL") != GIT_VALUES_REPO:
        errors.append("platform Helm ApplicationSet must use exactly one Git $values source from this repository")
    sync_policy = appset.get("spec", {}).get("template", {}).get("spec", {}).get("syncPolicy", {})
    if "automated" in sync_policy:
        errors.append("platform base template must not enable automated sync unconditionally")
    patch = appset.get("spec", {}).get("templatePatch", "")
    if "if .autoSync" not in patch or "automated:" not in patch:
        errors.append("platform ApplicationSet must gate automated sync through the autoSync template condition")

    resources_source = resources_appset.get("spec", {}).get("template", {}).get("spec", {}).get("source", {})
    if resources_source.get("repoURL") != GIT_VALUES_REPO:
        errors.append("platform resources ApplicationSet must source this repository")
    if resources_source.get("path") != "gitops-config/platform/resources":
        errors.append("platform resources ApplicationSet must reconcile gitops-config/platform/resources")
    resources_sync = resources_appset.get("spec", {}).get("template", {}).get("spec", {}).get("syncPolicy", {})
    if "automated" in resources_sync:
        errors.append("platform resources base template must not enable automated sync unconditionally")
    resources_patch = resources_appset.get("spec", {}).get("templatePatch", "")
    if "if .autoSync" not in resources_patch or "automated:" not in resources_patch:
        errors.append("platform resources ApplicationSet must gate automated sync through autoSync")

    if gateway_class.get("kind") != "GatewayClass":
        errors.append("platform gateway resource must be a GatewayClass")
    controller = gateway_class.get("spec", {}).get("controllerName")
    if controller != "gateway.envoyproxy.io/gatewayclass-controller":
        errors.append(f"GatewayClass controllerName is unexpected: {controller!r}")

    return errors, components, environments


def emit_helm_matrix(components: list[dict], environments: list[dict]) -> None:
    for component in components:
        for environment in environments:
            name = str(component["component"])
            env = str(environment["env"])
            common = VALUES_ROOT / name / "common.yaml"
            override = VALUES_ROOT / name / f"{env}.yaml"
            fields = [
                name,
                str(component["release"]),
                str(component["chart"]),
                str(component["repo"]),
                str(component["version"]),
                str(component["namespace"]),
                env,
                common.relative_to(ROOT).as_posix(),
                override.relative_to(ROOT).as_posix() if override.is_file() else "-",
            ]
            print("\t".join(fields))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--emit-helm-matrix", action="store_true")
    args = parser.parse_args()

    errors, components, environments = validate()
    if errors:
        print("GitOps contract validation failed:", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        return 1

    if args.emit_helm_matrix:
        emit_helm_matrix(components, environments)
    else:
        print(
            f"GitOps contract passed: {len(components)} platform components across "
            f"{len(environments)} environments."
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
