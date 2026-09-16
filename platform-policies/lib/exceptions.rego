package goldenpath.exceptionlib

import rego.v1

# The compiled registry is injected as base data at this exact path. Keep this
# reference static so OPA does not traverse sibling virtual documents under
# data.goldenpath and introduce policy recursion.
compiled_registry := data.goldenpath.policy_exceptions
exceptions := object.get(compiled_registry, "exceptions", [])

kubernetes_matches(policy, resource) := [exception |
    exception := exceptions[_]
    exception.target == "kubernetes"
    exception.policy == policy
    kind := lower(object.get(resource, "kind", ""))
    metadata := object.get(resource, "metadata", {})
    name := object.get(metadata, "name", "")
    namespace := object.get(metadata, "namespace", "default")
    exception.resource == sprintf("%s/%s", [kind, name])
    exception.namespace == namespace
]

kubernetes_exempt(policy, resource) if {
    count(kubernetes_matches(policy, resource)) == 1
}

kubernetes_exception(policy, resource) := exception if {
    matches := kubernetes_matches(policy, resource)
    count(matches) == 1
    exception := matches[0]
}

terraform_address_matches(policy, address) := [exception |
    exception := exceptions[_]
    exception.target == "terraform"
    exception.policy == policy
    exception.resource == address
]

terraform_address_exempt(policy, address) if {
    count(terraform_address_matches(policy, address)) == 1
}

terraform_exception_for_address(policy, address) := exception if {
    matches := terraform_address_matches(policy, address)
    count(matches) == 1
    exception := matches[0]
}

terraform_exempt(policy, resource) if {
    terraform_address_exempt(policy, object.get(resource, "address", ""))
}

terraform_exception(policy, resource) := exception if {
    exception := terraform_exception_for_address(policy, object.get(resource, "address", ""))
}
