# Política: Denegar wildcards en IAM
# Descripción: Prohibe el uso de wildcards en políticas IAM (principio de least privilege)
package terraform.security

import future.keywords.in

# Denegar políticas IAM con Action: *
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_iam_policy"
    policy := json.unmarshal(resource.change.after.policy)
    statement := policy.Statement[_]
    statement.Effect == "Allow"
    statement.Action[_] == "*"
    msg := sprintf("IAM policy '%s' contiene Action: '*'. Use acciones específicas", [resource.address])
}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_iam_role_policy"
    policy := json.unmarshal(resource.change.after.policy)
    statement := policy.Statement[_]
    statement.Effect == "Allow"
    statement.Action[_] == "*"
    msg := sprintf("IAM role policy '%s' contiene Action: '*'. Use acciones específicas", [resource.address])
}

# Denegar Resource: * para acciones sensibles
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_iam_policy"
    policy := json.unmarshal(resource.change.after.policy)
    statement := policy.Statement[_]
    statement.Effect == "Allow"
    statement.Resource == "*"
    has_sensitive_action(statement.Action)
    msg := sprintf("IAM policy '%s' tiene Resource: '*' con acciones sensibles", [resource.address])
}

# Acciones sensibles que no deberían tener Resource: *
sensitive_actions := {
    "iam:*",
    "iam:CreateUser",
    "iam:DeleteUser",
    "iam:AttachUserPolicy",
    "iam:PutUserPolicy",
    "sts:AssumeRole",
    "kms:*",
    "kms:Decrypt",
    "secretsmanager:GetSecretValue",
    "ssm:GetParameter"
}

has_sensitive_action(actions) {
    action := actions[_]
    action in sensitive_actions
}

has_sensitive_action(actions) {
    action := actions[_]
    startswith(action, "iam:")
}

# Advertir sobre NotAction
warn[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_iam_policy"
    policy := json.unmarshal(resource.change.after.policy)
    statement := policy.Statement[_]
    statement.NotAction
    msg := sprintf("IAM policy '%s' usa NotAction, lo cual puede ser peligroso. Revise cuidadosamente", [resource.address])
}

# Advertir sobre NotResource
warn[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_iam_policy"
    policy := json.unmarshal(resource.change.after.policy)
    statement := policy.Statement[_]
    statement.NotResource
    msg := sprintf("IAM policy '%s' usa NotResource, lo cual puede ser peligroso. Revise cuidadosamente", [resource.address])
}
