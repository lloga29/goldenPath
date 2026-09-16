# Require immutable image references for Kubernetes workloads.
package kubernetes.images

import rego.v1

controller_kinds := {"Deployment", "StatefulSet", "DaemonSet", "Job"}

containers contains container if {
    input.kind == "Pod"
    container := input.spec.containers[_]
}

containers contains container if {
    input.kind == "Pod"
    init_containers := object.get(input.spec, "initContainers", [])
    container := init_containers[_]
}

containers contains container if {
    input.kind in controller_kinds
    container := input.spec.template.spec.containers[_]
}

containers contains container if {
    input.kind in controller_kinds
    init_containers := object.get(input.spec.template.spec, "initContainers", [])
    container := init_containers[_]
}

containers contains container if {
    input.kind == "CronJob"
    container := input.spec.jobTemplate.spec.template.spec.containers[_]
}

containers contains container if {
    input.kind == "CronJob"
    init_containers := object.get(input.spec.jobTemplate.spec.template.spec, "initContainers", [])
    container := init_containers[_]
}

immutable_image_reference(image) if {
    regex.match(`@sha256:[a-fA-F0-9]{64}$`, image)
}

immutable_image_reference(image) if {
    regex.match(`:[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}$`, image)
    not endswith(image, ":latest")
}

deny contains msg if {
    container := containers[_]
    not immutable_image_reference(container.image)
    name := object.get(input.metadata, "name", "unknown")
    msg := sprintf("%s '%s': container '%s' must use an explicit immutable tag or SHA-256 digest instead of '%s'.", [input.kind, name, container.name, container.image])
}
