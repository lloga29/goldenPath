# Política: Resources obligatorios
# Descripción: Todos los containers deben tener requests y limits definidos
package kubernetes.resources

import future.keywords.in

# Denegar containers sin memory request
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.resources.requests.memory
    msg := sprintf("Deployment '%s': container '%s' debe tener resources.requests.memory", [input.metadata.name, container.name])
}

# Denegar containers sin cpu request
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.resources.requests.cpu
    msg := sprintf("Deployment '%s': container '%s' debe tener resources.requests.cpu", [input.metadata.name, container.name])
}

# Denegar containers sin memory limit
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.resources.limits.memory
    msg := sprintf("Deployment '%s': container '%s' debe tener resources.limits.memory", [input.metadata.name, container.name])
}

# Advertir si no tiene cpu limit (no siempre requerido)
warn[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.resources.limits.cpu
    msg := sprintf("Deployment '%s': container '%s' debería tener resources.limits.cpu", [input.metadata.name, container.name])
}
