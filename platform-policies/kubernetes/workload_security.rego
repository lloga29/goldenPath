# Política: Seguridad de workloads Kubernetes
# Descripción: Políticas de seguridad para pods y deployments
package kubernetes.workload

import future.keywords.in

# Denegar containers privilegiados
deny[msg] {
    input.kind == "Pod"
    container := input.spec.containers[_]
    container.securityContext.privileged == true
    msg := sprintf("Container '%s' no puede ejecutar como privilegiado", [container.name])
}

deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    container.securityContext.privileged == true
    msg := sprintf("Container '%s' en Deployment no puede ejecutar como privilegiado", [container.name])
}

# Denegar hostNetwork
deny[msg] {
    input.kind == "Pod"
    input.spec.hostNetwork == true
    msg := "Pods no pueden usar hostNetwork"
}

deny[msg] {
    input.kind == "Deployment"
    input.spec.template.spec.hostNetwork == true
    msg := "Deployments no pueden usar hostNetwork"
}

# Denegar hostPID
deny[msg] {
    input.kind == "Pod"
    input.spec.hostPID == true
    msg := "Pods no pueden usar hostPID"
}

# Denegar hostIPC
deny[msg] {
    input.kind == "Pod"
    input.spec.hostIPC == true
    msg := "Pods no pueden usar hostIPC"
}

# Requerir límites de recursos
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.resources.limits.memory
    msg := sprintf("Container '%s' debe tener memory limits definidos", [container.name])
}

deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.resources.limits.cpu
    msg := sprintf("Container '%s' debe tener CPU limits definidos", [container.name])
}

deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.resources.requests.memory
    msg := sprintf("Container '%s' debe tener memory requests definidos", [container.name])
}

# Denegar tag :latest
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    endswith(container.image, ":latest")
    msg := sprintf("Container '%s' no puede usar tag ':latest'. Use versiones específicas", [container.name])
}

deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not contains(container.image, ":")
    msg := sprintf("Container '%s' no tiene tag especificado. Use versiones específicas", [container.name])
}

# Advertir si no hay probes
warn[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.livenessProbe
    msg := sprintf("Container '%s' debería tener liveness probe", [container.name])
}

warn[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.readinessProbe
    msg := sprintf("Container '%s' debería tener readiness probe", [container.name])
}

# Requerir runAsNonRoot
deny[msg] {
    input.kind == "Deployment"
    not input.spec.template.spec.securityContext.runAsNonRoot
    msg := "Deployment debe tener securityContext.runAsNonRoot = true"
}

# Denegar allowPrivilegeEscalation
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    container.securityContext.allowPrivilegeEscalation == true
    msg := sprintf("Container '%s' no puede tener allowPrivilegeEscalation = true", [container.name])
}
