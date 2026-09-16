# Enforce workload isolation properties that are independent of container image/resource policies.
package kubernetes.workload

import future.keywords.in

controller_kinds := {"Deployment", "StatefulSet", "DaemonSet", "Job"}
long_running_controller_kinds := {"Deployment", "StatefulSet", "DaemonSet"}

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

deny[msg] {
    spec := pod_specs[_]
    object.get(spec, "hostNetwork", false) == true
    msg := sprintf("%s '%s' must not use hostNetwork.", [input.kind, input.metadata.name])
}

deny[msg] {
    spec := pod_specs[_]
    object.get(spec, "hostPID", false) == true
    msg := sprintf("%s '%s' must not use hostPID.", [input.kind, input.metadata.name])
}

deny[msg] {
    spec := pod_specs[_]
    object.get(spec, "hostIPC", false) == true
    msg := sprintf("%s '%s' must not use hostIPC.", [input.kind, input.metadata.name])
}

deny[msg] {
    spec := pod_specs[_]
    container := spec.containers[_]
    security_context := object.get(container, "securityContext", {})
    object.get(security_context, "privileged", false) == true
    msg := sprintf("%s '%s': container '%s' must not run privileged.", [input.kind, input.metadata.name, container.name])
}

warn[msg] {
    input.kind in long_running_controller_kinds
    container := input.spec.template.spec.containers[_]
    not container.livenessProbe
    msg := sprintf("%s '%s': container '%s' should define a liveness probe.", [input.kind, input.metadata.name, container.name])
}

warn[msg] {
    input.kind in long_running_controller_kinds
    container := input.spec.template.spec.containers[_]
    not container.readinessProbe
    msg := sprintf("%s '%s': container '%s' should define a readiness probe.", [input.kind, input.metadata.name, container.name])
}
