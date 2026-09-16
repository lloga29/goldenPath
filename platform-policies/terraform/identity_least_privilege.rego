# Reject provider-native identity grants that are unacceptably broad for the declared scope.
package terraform.identity

import rego.v1

aws_admin_policy_arns := {
    "arn:aws:iam::aws:policy/AdministratorAccess"
}

aws_managed_policy_attachment_types := {
    "aws_iam_role_policy_attachment",
    "aws_iam_user_policy_attachment",
    "aws_iam_group_policy_attachment"
}

azure_privileged_role_names := {
    "owner",
    "contributor",
    "user access administrator",
    "role based access control administrator"
}

azure_privileged_role_ids := {
    "8e3af657-a8ff-443c-a75c-2fe8c4bcb635",
    "b24988ac-6180-42a0-ab88-20f7382dd24c",
    "18d7d88d-d35e-4fb5-a5c3-7773c20a72d9",
    "f58310d9-a9f6-439a-9e8d-f62e7b41a168"
}

gcp_broad_roles := {
    "roles/owner",
    "roles/editor"
}

gcp_iam_binding_types := {
    "google_project_iam_binding",
    "google_project_iam_member",
    "google_folder_iam_binding",
    "google_folder_iam_member",
    "google_organization_iam_binding",
    "google_organization_iam_member"
}

azure_privileged_role(after) if {
    name := lower(object.get(after, "role_definition_name", ""))
    name in azure_privileged_role_names
}

azure_privileged_role(after) if {
    role_id := lower(object.get(after, "role_definition_id", ""))
    privileged_id := azure_privileged_role_ids[_]
    contains(role_id, privileged_id)
}

azure_broad_scope(scope) if {
    regex.match(`^/subscriptions/[^/]+$`, scope)
}

azure_broad_scope(scope) if {
    regex.match(`^/providers/Microsoft\.Management/managementGroups/[^/]+$`, scope)
}

violations contains {"resource": resource.address, "msg": msg} if {
    resource := input.resource_changes[_]
    resource.type in aws_managed_policy_attachment_types
    resource.change.actions[_] in ["create", "update"]
    policy_arn := object.get(resource.change.after, "policy_arn", "")
    policy_arn in aws_admin_policy_arns
    msg := sprintf("AWS identity attachment '%s' must not grant AdministratorAccess.", [resource.address])
}

violations contains {"resource": resource.address, "msg": msg} if {
    resource := input.resource_changes[_]
    resource.type == "azurerm_role_assignment"
    resource.change.actions[_] in ["create", "update"]
    after := resource.change.after
    azure_privileged_role(after)
    scope := object.get(after, "scope", "")
    azure_broad_scope(scope)
    msg := sprintf("Azure role assignment '%s' grants a privileged role at broad scope '%s'. Use a narrower role and/or resource scope.", [resource.address, scope])
}

violations contains {"resource": resource.address, "msg": msg} if {
    resource := input.resource_changes[_]
    resource.type in gcp_iam_binding_types
    resource.change.actions[_] in ["create", "update"]
    role := object.get(resource.change.after, "role", "")
    role in gcp_broad_roles
    msg := sprintf("Google Cloud IAM resource '%s' grants broad basic role '%s'. Use a narrowly scoped predefined or custom role.", [resource.address, role])
}

deny contains msg if {
    result := violations[_]
    msg := result.msg
}
