# Require provider-native ownership, environment, and cost-allocation metadata.
package terraform.compliance

import rego.v1

aws_required_tags := {"Environment", "Team", "CostCenter", "Owner"}
azure_required_tags := {"Environment", "Team", "CostCenter", "Owner"}
gcp_required_labels := {"environment", "team", "cost_center", "owner"}

aws_taggable_types := {
    "aws_instance",
    "aws_vpc",
    "aws_subnet",
    "aws_security_group",
    "aws_db_instance",
    "aws_rds_cluster",
    "aws_s3_bucket",
    "aws_lambda_function",
    "aws_ecs_cluster",
    "aws_ecs_service",
    "aws_eks_cluster",
    "aws_elasticache_cluster",
    "aws_elasticsearch_domain",
    "aws_kinesis_stream",
    "aws_sqs_queue",
    "aws_sns_topic",
    "aws_dynamodb_table"
}

azure_taggable_types := {
    "azurerm_resource_group",
    "azurerm_virtual_network",
    "azurerm_network_security_group",
    "azurerm_storage_account",
    "azurerm_linux_virtual_machine",
    "azurerm_windows_virtual_machine",
    "azurerm_kubernetes_cluster"
}

gcp_labelable_types := {
    "google_storage_bucket",
    "google_compute_instance"
}

valid_environment(env) if {
    env in ["dev", "staging", "prod", "ephemeral"]
}

violations contains {"resource": resource.address, "msg": msg} if {
    resource := input.resource_changes[_]
    resource.type in aws_taggable_types
    resource.change.actions[_] in ["create", "update"]
    tags := object.get(resource.change.after, "tags", {})
    present := {key | tags[key]; tags[key] != ""}
    missing := aws_required_tags - present
    count(missing) > 0
    msg := sprintf("AWS resource '%s' is missing required tags: %v", [resource.address, missing])
}

violations contains {"resource": resource.address, "msg": msg} if {
    resource := input.resource_changes[_]
    resource.type in aws_taggable_types
    resource.change.actions[_] in ["create", "update"]
    tags := object.get(resource.change.after, "tags", {})
    env := object.get(tags, "Environment", "")
    env != ""
    not valid_environment(env)
    msg := sprintf("AWS resource '%s' has invalid Environment tag '%s'. Allowed values: dev, staging, prod, ephemeral.", [resource.address, env])
}

violations contains {"resource": resource.address, "msg": msg} if {
    resource := input.resource_changes[_]
    resource.type in azure_taggable_types
    resource.change.actions[_] in ["create", "update"]
    tags := object.get(resource.change.after, "tags", {})
    present := {key | tags[key]; tags[key] != ""}
    missing := azure_required_tags - present
    count(missing) > 0
    msg := sprintf("Azure resource '%s' is missing required tags: %v", [resource.address, missing])
}

violations contains {"resource": resource.address, "msg": msg} if {
    resource := input.resource_changes[_]
    resource.type in azure_taggable_types
    resource.change.actions[_] in ["create", "update"]
    tags := object.get(resource.change.after, "tags", {})
    env := object.get(tags, "Environment", "")
    env != ""
    not valid_environment(env)
    msg := sprintf("Azure resource '%s' has invalid Environment tag '%s'. Allowed values: dev, staging, prod, ephemeral.", [resource.address, env])
}

violations contains {"resource": resource.address, "msg": msg} if {
    resource := input.resource_changes[_]
    resource.type in gcp_labelable_types
    resource.change.actions[_] in ["create", "update"]
    labels := object.get(resource.change.after, "labels", {})
    present := {key | labels[key]; labels[key] != ""}
    missing := gcp_required_labels - present
    count(missing) > 0
    msg := sprintf("Google Cloud resource '%s' is missing required labels: %v", [resource.address, missing])
}

violations contains {"resource": resource.address, "msg": msg} if {
    resource := input.resource_changes[_]
    resource.type in gcp_labelable_types
    resource.change.actions[_] in ["create", "update"]
    labels := object.get(resource.change.after, "labels", {})
    env := object.get(labels, "environment", "")
    env != ""
    not valid_environment(env)
    msg := sprintf("Google Cloud resource '%s' has invalid environment label '%s'. Allowed values: dev, staging, prod, ephemeral.", [resource.address, env])
}

deny contains msg if {
    result := violations[_]
    msg := result.msg
}

warn contains msg if {
    resource := input.resource_changes[_]
    resource.type in aws_taggable_types
    tags := object.get(resource.change.after, "tags", {})
    cost_center := object.get(tags, "CostCenter", "")
    cost_center != ""
    not regex.match(`^cc-[a-z0-9]+(-[a-z0-9]+)*$`, lower(cost_center))
    msg := sprintf("AWS resource '%s' has CostCenter '%s' with an invalid format. Use cc-<segment>[-<segment>...].", [resource.address, cost_center])
}

warn contains msg if {
    resource := input.resource_changes[_]
    resource.type in azure_taggable_types
    tags := object.get(resource.change.after, "tags", {})
    cost_center := object.get(tags, "CostCenter", "")
    cost_center != ""
    not regex.match(`^cc-[a-z0-9]+(-[a-z0-9]+)*$`, lower(cost_center))
    msg := sprintf("Azure resource '%s' has CostCenter '%s' with an invalid format. Use cc-<segment>[-<segment>...].", [resource.address, cost_center])
}

warn contains msg if {
    resource := input.resource_changes[_]
    resource.type in gcp_labelable_types
    labels := object.get(resource.change.after, "labels", {})
    cost_center := object.get(labels, "cost_center", "")
    cost_center != ""
    not regex.match(`^cc-[a-z0-9]+(-[a-z0-9]+)*$`, lower(cost_center))
    msg := sprintf("Google Cloud resource '%s' has cost_center '%s' with an invalid format. Use cc-<segment>[-<segment>...].", [resource.address, cost_center])
}

warn contains msg if {
    resource := input.resource_changes[_]
    resource.type in aws_taggable_types
    tags := object.get(resource.change.after, "tags", {})
    owner := object.get(tags, "Owner", "")
    owner != ""
    not regex.match(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`, owner)
    msg := sprintf("AWS resource '%s' has Owner '%s', which is not a valid email address.", [resource.address, owner])
}

warn contains msg if {
    resource := input.resource_changes[_]
    resource.type in azure_taggable_types
    tags := object.get(resource.change.after, "tags", {})
    owner := object.get(tags, "Owner", "")
    owner != ""
    not regex.match(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`, owner)
    msg := sprintf("Azure resource '%s' has Owner '%s', which is not a valid email address.", [resource.address, owner])
}
