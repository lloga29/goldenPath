# Política: Prohibir uso de tag :latest
# Descripción: Las imágenes deben usar tags inmutables (semver o SHA)
package kubernetes.images

import future.keywords.in

# Denegar deployments con :latest
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    image := container.image
    endswith(image, ":latest")
    msg := sprintf("Deployment '%s': container '%s' usa tag ':latest'. Use un tag inmutable (semver o SHA).", [input.metadata.name, container.name])
}

deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    image := container.image
    not contains(image, ":")
    msg := sprintf("Deployment '%s': container '%s' no tiene tag explícito. Use un tag inmutable.", [input.metadata.name, container.name])
}

# Denegar init containers con :latest
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.initContainers[_]
    image := container.image
    endswith(image, ":latest")
    msg := sprintf("Deployment '%s': initContainer '%s' usa tag ':latest'.", [input.metadata.name, container.name])
}

# Aplicar también a StatefulSets y DaemonSets
deny[msg] {
    input.kind in ["StatefulSet", "DaemonSet"]
    container := input.spec.template.spec.containers[_]
    image := container.image
    endswith(image, ":latest")
    msg := sprintf("%s '%s': container '%s' usa tag ':latest'.", [input.kind, input.metadata.name, container.name])
}
