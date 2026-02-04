# Política: Contexto de seguridad obligatorio
# Descripción: Los pods deben ejecutar como non-root con contexto de seguridad restrictivo
package kubernetes.security

import future.keywords.in

# Denegar containers sin runAsNonRoot
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.securityContext.runAsNonRoot
    msg := sprintf("Deployment '%s': container '%s' debe tener securityContext.runAsNonRoot=true", [input.metadata.name, container.name])
}

# Denegar containers con allowPrivilegeEscalation
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    container.securityContext.allowPrivilegeEscalation == true
    msg := sprintf("Deployment '%s': container '%s' no puede tener allowPrivilegeEscalation=true", [input.metadata.name, container.name])
}

# Advertir si no tiene readOnlyRootFilesystem
warn[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.securityContext.readOnlyRootFilesystem
    msg := sprintf("Deployment '%s': container '%s' debería tener readOnlyRootFilesystem=true", [input.metadata.name, container.name])
}

# Denegar si no se dropean capabilities
warn[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.securityContext.capabilities.drop
    msg := sprintf("Deployment '%s': container '%s' debería dropear capabilities (al menos ALL)", [input.metadata.name, container.name])
}
