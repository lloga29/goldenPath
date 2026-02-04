# Política: Requerir tags obligatorios
# Descripción: Todos los recursos deben tener tags de governance
package terraform.compliance

import future.keywords.in

# Tags requeridos
required_tags := {"Environment", "Team", "CostCenter", "Owner"}

# Recursos que requieren tags
taggable_types := {
    "aws_instance",
    "aws_vpc",
    "aws_subnet",
    "aws_security_group",
    "aws_rds_instance",
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

# Denegar recursos sin tags requeridos
deny[msg] {
    resource := input.resource_changes[_]
    resource.type in taggable_types
    resource.change.actions[_] in ["create", "update"]
    
    tags := object.get(resource.change.after, "tags", {})
    missing := required_tags - {k | tags[k]}
    count(missing) > 0
    
    msg := sprintf("Recurso '%s' no tiene los tags requeridos: %v", [resource.address, missing])
}

# Validar valores de Environment
deny[msg] {
    resource := input.resource_changes[_]
    resource.type in taggable_types
    tags := object.get(resource.change.after, "tags", {})
    env := tags.Environment
    not valid_environment(env)
    msg := sprintf("Recurso '%s' tiene Environment '%s' inválido. Valores permitidos: dev, staging, prod, ephemeral", [resource.address, env])
}

valid_environment(env) {
    env in ["dev", "staging", "prod", "ephemeral"]
}

# Validar formato de CostCenter
warn[msg] {
    resource := input.resource_changes[_]
    resource.type in taggable_types
    tags := object.get(resource.change.after, "tags", {})
    cc := tags.CostCenter
    not re_match(`^cc-[0-9]{3,6}$`, cc)
    msg := sprintf("Recurso '%s' tiene CostCenter '%s' con formato incorrecto. Use formato: cc-XXX", [resource.address, cc])
}

# Validar formato de Owner (email)
warn[msg] {
    resource := input.resource_changes[_]
    resource.type in taggable_types
    tags := object.get(resource.change.after, "tags", {})
    owner := tags.Owner
    not re_match(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`, owner)
    msg := sprintf("Recurso '%s' tiene Owner '%s' que no parece un email válido", [resource.address, owner])
}
