package goldenpath.terraform

import rego.v1
import data.goldenpath.exceptionlib

public_access_policy_id := "terraform.public_access"
iam_policy_id := "terraform.iam.no_wildcards"
encryption_policy_id := "terraform.encryption.required"
tags_policy_id := "terraform.tags.required"

filtered_input(policy_id) := object.union(input, {"resource_changes": [resource |
    resource := object.get(input, "resource_changes", [])[_]
    not exceptionlib.terraform_exempt(policy_id, resource)
]})

deny contains msg if {
    filtered := filtered_input(public_access_policy_id)
    msg := data.terraform.public_access.deny[_] with input as filtered
}

deny contains msg if {
    filtered := filtered_input(iam_policy_id)
    msg := data.terraform.iam.deny[_] with input as filtered
}

deny contains msg if {
    filtered := filtered_input(encryption_policy_id)
    msg := data.terraform.encryption.deny[_] with input as filtered
}

deny contains msg if {
    filtered := filtered_input(tags_policy_id)
    msg := data.terraform.compliance.deny[_] with input as filtered
}

warn contains msg if {
    msg := data.terraform.iam.warn[_]
}

warn contains msg if {
    msg := data.terraform.encryption.warn[_]
}

warn contains msg if {
    msg := data.terraform.compliance.warn[_]
}

warn contains msg if {
    resource := object.get(input, "resource_changes", [])[_]
    exception := exceptionlib.terraform_exception(public_access_policy_id, resource)
    msg := sprintf("Policy exception %s suppresses %s deny results for exact Terraform address %s.", [exception.id, public_access_policy_id, exception.resource])
}

warn contains msg if {
    resource := object.get(input, "resource_changes", [])[_]
    exception := exceptionlib.terraform_exception(iam_policy_id, resource)
    msg := sprintf("Policy exception %s suppresses %s deny results for exact Terraform address %s.", [exception.id, iam_policy_id, exception.resource])
}

warn contains msg if {
    resource := object.get(input, "resource_changes", [])[_]
    exception := exceptionlib.terraform_exception(encryption_policy_id, resource)
    msg := sprintf("Policy exception %s suppresses %s deny results for exact Terraform address %s.", [exception.id, encryption_policy_id, exception.resource])
}

warn contains msg if {
    resource := object.get(input, "resource_changes", [])[_]
    exception := exceptionlib.terraform_exception(tags_policy_id, resource)
    msg := sprintf("Policy exception %s suppresses %s deny results for exact Terraform address %s.", [exception.id, tags_policy_id, exception.resource])
}
