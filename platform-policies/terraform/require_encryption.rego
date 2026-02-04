# Política: Requerir encriptación
# Descripción: Todos los recursos de almacenamiento deben estar encriptados
package terraform.security

import future.keywords.in

# Requerir encriptación en EBS volumes
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_ebs_volume"
    not resource.change.after.encrypted
    msg := sprintf("EBS volume '%s' debe estar encriptado", [resource.address])
}

# Requerir encriptación en RDS
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    not resource.change.after.storage_encrypted
    msg := sprintf("RDS instance '%s' debe tener storage_encrypted = true", [resource.address])
}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_rds_cluster"
    not resource.change.after.storage_encrypted
    msg := sprintf("RDS cluster '%s' debe tener storage_encrypted = true", [resource.address])
}

# Requerir encriptación en S3
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket"
    not has_encryption(resource)
    msg := sprintf("S3 bucket '%s' debe tener encriptación habilitada", [resource.address])
}

has_encryption(resource) {
    resource.change.after.server_side_encryption_configuration[_]
}

# Requerir encriptación en ElastiCache
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_elasticache_replication_group"
    not resource.change.after.at_rest_encryption_enabled
    msg := sprintf("ElastiCache '%s' debe tener at_rest_encryption_enabled = true", [resource.address])
}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_elasticache_replication_group"
    not resource.change.after.transit_encryption_enabled
    msg := sprintf("ElastiCache '%s' debe tener transit_encryption_enabled = true", [resource.address])
}

# Requerir KMS key para encriptación
warn[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_ebs_volume"
    resource.change.after.encrypted
    not resource.change.after.kms_key_id
    msg := sprintf("EBS volume '%s' está encriptado pero debería usar una KMS key específica", [resource.address])
}
