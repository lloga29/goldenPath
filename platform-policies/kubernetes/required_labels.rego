# Require standard ownership and application labels on Kubernetes resources.
package kubernetes.compliance

import future.keywords.in

required_labels := {
    "app.kubernetes.io/name",
    "app.kubernetes.io/component",
    "app.kubernetes.io/part-of",
    "team",
    "environment"
}

labeled_resources := {"Pod", "Deployment", "StatefulSet", "DaemonSet", "Service", "Ingress", "Job", "CronJob"}
controller_kinds := {"Deployment", "StatefulSet", "DaemonSet", "Job"}

deny[msg] {
    input.kind in labeled_resources
    labels := object.get(input.metadata, "labels", {})
    present := {key | labels[key]}
    missing := required_labels - present
    count(missing) > 0
    msg := sprintf("%s '%s' is missing required labels: %v", [input.kind, input.metadata.name, missing])
}

deny[msg] {
    input.kind in controller_kinds
    labels := object.get(input.spec.template.metadata, "labels", {})
    present := {key | labels[key]}
    missing := required_labels - present
    count(missing) > 0
    msg := sprintf("%s '%s' pod template is missing required labels: %v", [input.kind, input.metadata.name, missing])
}

deny[msg] {
    input.kind == "CronJob"
    labels := object.get(input.spec.jobTemplate.spec.template.metadata, "labels", {})
    present := {key | labels[key]}
    missing := required_labels - present
    count(missing) > 0
    msg := sprintf("CronJob '%s' pod template is missing required labels: %v", [input.metadata.name, missing])
}

deny[msg] {
    input.kind in labeled_resources
    labels := object.get(input.metadata, "labels", {})
    env := object.get(labels, "environment", "")
    env != ""
    not valid_environment(env)
    msg := sprintf("%s '%s' has invalid environment label '%s'. Allowed values: dev, staging, prod, ephemeral.", [input.kind, input.metadata.name, env])
}

valid_environment(env) {
    env in ["dev", "staging", "prod", "ephemeral"]
}

warn[msg] {
    input.kind in labeled_resources
    labels := object.get(input.metadata, "labels", {})
    not labels["app.kubernetes.io/managed-by"]
    msg := sprintf("%s '%s' should declare app.kubernetes.io/managed-by.", [input.kind, input.metadata.name])
}
