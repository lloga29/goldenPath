# Require CPU and memory requests/limits on workload containers.
package kubernetes.resources

import rego.v1

controller_kinds := {"Deployment", "StatefulSet", "DaemonSet", "Job"}

pod_specs contains spec if {
    input.kind == "Pod"
    spec := input.spec
}

pod_specs contains spec if {
    input.kind in controller_kinds
    spec := input.spec.template.spec
}

pod_specs contains spec if {
    input.kind == "CronJob"
    spec := input.spec.jobTemplate.spec.template.spec
}

containers contains container if {
    spec := pod_specs[_]
    container := spec.containers[_]
}

containers contains container if {
    spec := pod_specs[_]
    init_containers := object.get(spec, "initContainers", [])
    container := init_containers[_]
}

deny contains msg if {
    container := containers[_]
    resources := object.get(container, "resources", {})
    requests := object.get(resources, "requests", {})
    object.get(requests, "memory", "") == ""
    msg := sprintf("%s '%s': container '%s' must define resources.requests.memory.", [input.kind, input.metadata.name, container.name])
}

deny contains msg if {
    container := containers[_]
    resources := object.get(container, "resources", {})
    requests := object.get(resources, "requests", {})
    object.get(requests, "cpu", "") == ""
    msg := sprintf("%s '%s': container '%s' must define resources.requests.cpu.", [input.kind, input.metadata.name, container.name])
}

deny contains msg if {
    container := containers[_]
    resources := object.get(container, "resources", {})
    limits := object.get(resources, "limits", {})
    object.get(limits, "memory", "") == ""
    msg := sprintf("%s '%s': container '%s' must define resources.limits.memory.", [input.kind, input.metadata.name, container.name])
}

deny contains msg if {
    container := containers[_]
    resources := object.get(container, "resources", {})
    limits := object.get(resources, "limits", {})
    object.get(limits, "cpu", "") == ""
    msg := sprintf("%s '%s': container '%s' must define resources.limits.cpu.", [input.kind, input.metadata.name, container.name])
}
