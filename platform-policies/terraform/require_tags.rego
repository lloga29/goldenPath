# Require ownership, environment, and cost-allocation tags on supported AWS resources.
package terraform.compliance

import rego.v1

required_tags := {"Environment", "Team", "CostCenter", "Owner"}

taggable_types := {
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

deny contains msg if {
    resource := input.resource_changes[_]
    resource.type in taggable_types
    resource.change.actions[_] in ["create", "update"]
    tags := object.get(resource.change.after, "tags", {})
    present := {key | tags[key]; tags[key] != ""}
    missing := required_tags - present
    count(missing) > 0
    msg := sprintf("Terraform resource '%s' is missing required tags: %v", [resource.address, missing])
}

deny contains msg if {
    resource := input.resource_changes[_]
    resource.type in taggable_types
    resource.change.actions[_] in ["create", "update"]
    tags := object.get(resource.change.after, "tags", {})
    env := object.get(tags, "Environment", "")
    env != ""
    not valid_environment(env)
    msg := sprintf("Terraform resource '%s' has invalid Environment tag '%s'. Allowed values: dev, staging, prod, ephemeral.", [resource.address, env])
}

valid_environment(env) if {
    env in ["dev", "staging", "prod", "ephemeral"]
}

warn contains msg if {
    resource := input.resource_changes[_]
    resource.type in taggable_types
    tags := object.get(resource.change.after, "tags", {})
    cost_center := object.get(tags, "CostCenter", "")
    cost_center != ""
    not regex.match(`^cc-[a-z0-9]+(-[a-z0-9]+)*$`, cost_center)
    msg := sprintf("Terraform resource '%s' has CostCenter '%s' with an invalid format. Use cc-<segment>[-<segment>...].", [resource.address, cost_center])
}

warn contains msg if {
    resource := input.resource_changes[_]
    resource.type in taggable_types
    tags := object.get(resource.change.after, "tags", {})
    owner := object.get(tags, "Owner", "")
    owner != ""
    not regex.match(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`, owner)
    msg := sprintf("Terraform resource '%s' has Owner '%s', which is not a valid email address.", [resource.address, owner])
}
