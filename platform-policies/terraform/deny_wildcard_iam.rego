# Reject dangerous wildcard IAM permissions for supported inline/managed AWS policies.
package terraform.security

import rego.v1

iam_policy_types := {"aws_iam_policy", "aws_iam_role_policy", "aws_iam_user_policy", "aws_iam_group_policy"}

has_full_wildcard_action(statement) if {
    is_string(statement.Action)
    statement.Action == "*"
}

has_full_wildcard_action(statement) if {
    is_array(statement.Action)
    statement.Action[_] == "*"
}

has_wildcard_resource(statement) if {
    is_string(statement.Resource)
    statement.Resource == "*"
}

has_wildcard_resource(statement) if {
    is_array(statement.Resource)
    statement.Resource[_] == "*"
}

sensitive_action(action) if {
    startswith(action, "iam:")
}

sensitive_action(action) if {
    startswith(action, "kms:")
}

sensitive_action(action) if {
    action in {"sts:AssumeRole", "secretsmanager:GetSecretValue", "ssm:GetParameter", "ssm:GetParameters", "ssm:GetParametersByPath"}
}

has_sensitive_action(statement) if {
    is_string(statement.Action)
    sensitive_action(statement.Action)
}

has_sensitive_action(statement) if {
    is_array(statement.Action)
    action := statement.Action[_]
    sensitive_action(action)
}

deny contains msg if {
    resource := input.resource_changes[_]
    resource.type in iam_policy_types
    resource.change.actions[_] in ["create", "update"]
    policy_json := object.get(resource.change.after, "policy", "")
    policy_json != ""
    policy := json.unmarshal(policy_json)
    statement := policy.Statement[_]
    statement.Effect == "Allow"
    has_full_wildcard_action(statement)
    msg := sprintf("IAM policy resource '%s' contains Allow Action '*'. Use explicit actions.", [resource.address])
}

deny contains msg if {
    resource := input.resource_changes[_]
    resource.type in iam_policy_types
    resource.change.actions[_] in ["create", "update"]
    policy_json := object.get(resource.change.after, "policy", "")
    policy_json != ""
    policy := json.unmarshal(policy_json)
    statement := policy.Statement[_]
    statement.Effect == "Allow"
    has_wildcard_resource(statement)
    has_sensitive_action(statement)
    msg := sprintf("IAM policy resource '%s' grants a sensitive action against Resource '*'. Scope the resource explicitly.", [resource.address])
}

warn contains msg if {
    resource := input.resource_changes[_]
    resource.type in iam_policy_types
    policy_json := object.get(resource.change.after, "policy", "")
    policy_json != ""
    policy := json.unmarshal(policy_json)
    statement := policy.Statement[_]
    object.get(statement, "NotAction", null) != null
    msg := sprintf("IAM policy resource '%s' uses NotAction and requires explicit security review.", [resource.address])
}

warn contains msg if {
    resource := input.resource_changes[_]
    resource.type in iam_policy_types
    policy_json := object.get(resource.change.after, "policy", "")
    policy_json != ""
    policy := json.unmarshal(policy_json)
    statement := policy.Statement[_]
    object.get(statement, "NotResource", null) != null
    msg := sprintf("IAM policy resource '%s' uses NotResource and requires explicit security review.", [resource.address])
}
