# Política: Labels requeridos en Kubernetes
# Descripción: Todos los recursos deben tener labels estándar
package kubernetes.compliance

import future.keywords.in

# Labels requeridos
required_labels := {
    "app.kubernetes.io/name",
    "app.kubernetes.io/component", 
    "app.kubernetes.io/part-of",
    "team",
    "environment"
}

# Recursos que requieren labels
labeled_resources := {"Deployment", "StatefulSet", "DaemonSet", "Service", "Ingress"}

# Denegar recursos sin labels requeridos
deny[msg] {
    input.kind in labeled_resources
    labels := object.get(input.metadata, "labels", {})
    missing := required_labels - {k | labels[k]}
    count(missing) > 0
    msg := sprintf("%s '%s' no tiene los labels requeridos: %v", [input.kind, input.metadata.name, missing])
}

# Validar que los pods del Deployment también tengan labels
deny[msg] {
    input.kind == "Deployment"
    pod_labels := object.get(input.spec.template.metadata, "labels", {})
    not pod_labels["app.kubernetes.io/name"]
    msg := sprintf("Deployment '%s' no tiene label app.kubernetes.io/name en el pod template", [input.metadata.name])
}

# Validar valores de environment
deny[msg] {
    input.kind in labeled_resources
    labels := input.metadata.labels
    env := labels.environment
    not valid_environment(env)
    msg := sprintf("%s '%s' tiene environment '%s' inválido. Use: dev, staging, prod", [input.kind, input.metadata.name, env])
}

valid_environment(env) {
    env in ["dev", "staging", "prod", "ephemeral"]
}

# Advertir si falta app.kubernetes.io/version
warn[msg] {
    input.kind in labeled_resources
    labels := object.get(input.metadata, "labels", {})
    not labels["app.kubernetes.io/version"]
    msg := sprintf("%s '%s' debería tener label app.kubernetes.io/version", [input.kind, input.metadata.name])
}

# Advertir si falta app.kubernetes.io/managed-by
warn[msg] {
    input.kind in labeled_resources
    labels := object.get(input.metadata, "labels", {})
    not labels["app.kubernetes.io/managed-by"]
    msg := sprintf("%s '%s' debería tener label app.kubernetes.io/managed-by", [input.kind, input.metadata.name])
}
