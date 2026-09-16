package goldenpath.kubernetes

import rego.v1
import data.goldenpath.exceptionlib

images_policy_id := "kubernetes.images.immutable"
labels_policy_id := "kubernetes.labels.required"
resources_policy_id := "kubernetes.resources.required"
security_policy_id := "kubernetes.security.context"
workload_policy_id := "kubernetes.workload.isolation"

deny contains msg if {
    not exceptionlib.kubernetes_exempt(images_policy_id, input)
    msg := data.kubernetes.images.deny[_]
}

deny contains msg if {
    not exceptionlib.kubernetes_exempt(labels_policy_id, input)
    msg := data.kubernetes.compliance.deny[_]
}

deny contains msg if {
    not exceptionlib.kubernetes_exempt(resources_policy_id, input)
    msg := data.kubernetes.resources.deny[_]
}

deny contains msg if {
    not exceptionlib.kubernetes_exempt(security_policy_id, input)
    msg := data.kubernetes.security.deny[_]
}

deny contains msg if {
    not exceptionlib.kubernetes_exempt(workload_policy_id, input)
    msg := data.kubernetes.workload.deny[_]
}

# Preserve advisory warnings from implementation policies. Packages without
# warnings are intentionally omitted rather than relying on undefined documents.
warn contains msg if {
    msg := data.kubernetes.compliance.warn[_]
}

warn contains msg if {
    msg := data.kubernetes.security.warn[_]
}

warn contains msg if {
    msg := data.kubernetes.workload.warn[_]
}

warn contains msg if {
    data.kubernetes.images.deny[_]
    exception := exceptionlib.kubernetes_exception(images_policy_id, input)
    namespace := object.get(input.metadata, "namespace", "default")
    msg := sprintf("Policy exception %s suppresses %s deny results for exact scope %s in namespace %s.", [exception.id, images_policy_id, exception.resource, namespace])
}

warn contains msg if {
    data.kubernetes.compliance.deny[_]
    exception := exceptionlib.kubernetes_exception(labels_policy_id, input)
    namespace := object.get(input.metadata, "namespace", "default")
    msg := sprintf("Policy exception %s suppresses %s deny results for exact scope %s in namespace %s.", [exception.id, labels_policy_id, exception.resource, namespace])
}

warn contains msg if {
    data.kubernetes.resources.deny[_]
    exception := exceptionlib.kubernetes_exception(resources_policy_id, input)
    namespace := object.get(input.metadata, "namespace", "default")
    msg := sprintf("Policy exception %s suppresses %s deny results for exact scope %s in namespace %s.", [exception.id, resources_policy_id, exception.resource, namespace])
}

warn contains msg if {
    data.kubernetes.security.deny[_]
    exception := exceptionlib.kubernetes_exception(security_policy_id, input)
    namespace := object.get(input.metadata, "namespace", "default")
    msg := sprintf("Policy exception %s suppresses %s deny results for exact scope %s in namespace %s.", [exception.id, security_policy_id, exception.resource, namespace])
}

warn contains msg if {
    data.kubernetes.workload.deny[_]
    exception := exceptionlib.kubernetes_exception(workload_policy_id, input)
    namespace := object.get(input.metadata, "namespace", "default")
    msg := sprintf("Policy exception %s suppresses %s deny results for exact scope %s in namespace %s.", [exception.id, workload_policy_id, exception.resource, namespace])
}
