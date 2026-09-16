package goldenpath.terraform

import rego.v1
import data.goldenpath.exceptionlib

public_access_policy_id := "terraform.public_access"
iam_policy_id := "terraform.iam.no_wildcards"
identity_policy_id := "terraform.identity.least_privilege"
encryption_policy_id := "terraform.encryption.required"
tags_policy_id := "terraform.tags.required"

deny contains msg if {
    result := data.terraform.public_access.violations[_]
    not exceptionlib.terraform_address_exempt(public_access_policy_id, result.resource)
    msg := result.msg
}

deny contains msg if {
    result := data.terraform.iam.violations[_]
    not exceptionlib.terraform_address_exempt(iam_policy_id, result.resource)
    msg := result.msg
}

deny contains msg if {
    result := data.terraform.identity.violations[_]
    not exceptionlib.terraform_address_exempt(identity_policy_id, result.resource)
    msg := result.msg
}

deny contains msg if {
    result := data.terraform.encryption.violations[_]
    not exceptionlib.terraform_address_exempt(encryption_policy_id, result.resource)
    msg := result.msg
}

deny contains msg if {
    result := data.terraform.compliance.violations[_]
    not exceptionlib.terraform_address_exempt(tags_policy_id, result.resource)
    msg := result.msg
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
    result := data.terraform.public_access.violations[_]
    exception := exceptionlib.terraform_exception_for_address(public_access_policy_id, result.resource)
    msg := sprintf("Policy exception %s suppresses %s deny result for exact Terraform address %s.", [exception.id, public_access_policy_id, exception.resource])
}

warn contains msg if {
    result := data.terraform.iam.violations[_]
    exception := exceptionlib.terraform_exception_for_address(iam_policy_id, result.resource)
    msg := sprintf("Policy exception %s suppresses %s deny result for exact Terraform address %s.", [exception.id, iam_policy_id, exception.resource])
}

warn contains msg if {
    result := data.terraform.identity.violations[_]
    exception := exceptionlib.terraform_exception_for_address(identity_policy_id, result.resource)
    msg := sprintf("Policy exception %s suppresses %s deny result for exact Terraform address %s.", [exception.id, identity_policy_id, exception.resource])
}

warn contains msg if {
    result := data.terraform.encryption.violations[_]
    exception := exceptionlib.terraform_exception_for_address(encryption_policy_id, result.resource)
    msg := sprintf("Policy exception %s suppresses %s deny result for exact Terraform address %s.", [exception.id, encryption_policy_id, exception.resource])
}

warn contains msg if {
    result := data.terraform.compliance.violations[_]
    exception := exceptionlib.terraform_exception_for_address(tags_policy_id, result.resource)
    msg := sprintf("Policy exception %s suppresses %s deny result for exact Terraform address %s.", [exception.id, tags_policy_id, exception.resource])
}
