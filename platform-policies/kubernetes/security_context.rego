# Enforce a restrictive security context for Kubernetes workloads.
package kubernetes.security

import future.keywords.in

controller_kinds := {"Deployment", "StatefulSet", "DaemonSet", "Job"}

pod_specs[spec] {
    input.kind == "Pod"
    spec := input.spec
}

pod_specs[spec] {
    input.kind in controller_kinds
    spec := input.spec.template.spec
}

pod_specs[spec] {
    input.kind == "CronJob"
    spec := input.spec.jobTemplate.spec.template.spec
}

runs_as_non_root(pod_security_context, container_security_context) {
    object.get(container_security_context, "runAsNonRoot", false) == true
}

runs_as_non_root(pod_security_context, container_security_context) {
    object.get(pod_security_context, "runAsNonRoot", false) == true
}

drops_all_capabilities(container_security_context) {
    capabilities := object.get(container_security_context, "capabilities", {})
    drops := object.get(capabilities, "drop", [])
    drops[_] == "ALL"
}

deny[msg] {
    spec := pod_specs[_]
    pod_security_context := object.get(spec, "securityContext", {})
    container := spec.containers[_]
    container_security_context := object.get(container, "securityContext", {})
    not runs_as_non_root(pod_security_context, container_security_context)
    msg := sprintf("%s '%s': container '%s' must run as non-root at the pod or container level.", [input.kind, input.metadata.name, container.name])
}

deny[msg] {
    spec := pod_specs[_]
    container := spec.containers[_]
    container_security_context := object.get(container, "securityContext", {})
    object.get(container_security_context, "allowPrivilegeEscalation", true) != false
    msg := sprintf("%s '%s': container '%s' must set allowPrivilegeEscalation=false.", [input.kind, input.metadata.name, container.name])
}

warn[msg] {
    spec := pod_specs[_]
    container := spec.containers[_]
    container_security_context := object.get(container, "securityContext", {})
    object.get(container_security_context, "readOnlyRootFilesystem", false) != true
    msg := sprintf("%s '%s': container '%s' should set readOnlyRootFilesystem=true.", [input.kind, input.metadata.name, container.name])
}

warn[msg] {
    spec := pod_specs[_]
    container := spec.containers[_]
    container_security_context := object.get(container, "securityContext", {})
    not drops_all_capabilities(container_security_context)
    msg := sprintf("%s '%s': container '%s' should drop the ALL Linux capability set.", [input.kind, input.metadata.name, container.name])
}
