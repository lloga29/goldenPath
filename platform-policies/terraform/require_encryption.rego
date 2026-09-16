# Require encryption at rest/in transit for supported AWS resource types.
package terraform.security

import future.keywords.in

same_encryption_identity(bucket, companion) {
    object.get(bucket, "module_address", "") == object.get(companion, "module_address", "")
    bucket.name == companion.name
    object.get(bucket, "index", "") == object.get(companion, "index", "")
}

same_encryption_bucket_reference(bucket, companion) {
    bucket_name := object.get(bucket.change.after, "bucket", "")
    bucket_name != ""
    object.get(companion.change.after, "bucket", "") == bucket_name
}

same_encryption_bucket_reference(bucket, companion) {
    same_encryption_identity(bucket, companion)
}

s3_bucket_has_encryption(bucket) {
    companion := input.resource_changes[_]
    companion.type == "aws_s3_bucket_server_side_encryption_configuration"
    companion.change.actions[_] in ["create", "update", "no-op"]
    same_encryption_bucket_reference(bucket, companion)
}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_ebs_volume"
    resource.change.actions[_] in ["create", "update"]
    object.get(resource.change.after, "encrypted", false) != true
    msg := sprintf("EBS volume '%s' must enable encryption.", [resource.address])
}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    resource.change.actions[_] in ["create", "update"]
    object.get(resource.change.after, "storage_encrypted", false) != true
    msg := sprintf("RDS instance '%s' must set storage_encrypted=true.", [resource.address])
}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_rds_cluster"
    resource.change.actions[_] in ["create", "update"]
    object.get(resource.change.after, "storage_encrypted", false) != true
    msg := sprintf("RDS cluster '%s' must set storage_encrypted=true.", [resource.address])
}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket"
    resource.change.actions[_] in ["create", "update"]
    not s3_bucket_has_encryption(resource)
    msg := sprintf("S3 bucket '%s' must have a matching aws_s3_bucket_server_side_encryption_configuration resource.", [resource.address])
}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_elasticache_replication_group"
    resource.change.actions[_] in ["create", "update"]
    object.get(resource.change.after, "at_rest_encryption_enabled", false) != true
    msg := sprintf("ElastiCache replication group '%s' must enable at-rest encryption.", [resource.address])
}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_elasticache_replication_group"
    resource.change.actions[_] in ["create", "update"]
    object.get(resource.change.after, "transit_encryption_enabled", false) != true
    msg := sprintf("ElastiCache replication group '%s' must enable in-transit encryption.", [resource.address])
}

warn[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_ebs_volume"
    object.get(resource.change.after, "encrypted", false) == true
    object.get(resource.change.after, "kms_key_id", "") == ""
    msg := sprintf("EBS volume '%s' is encrypted but should use an explicitly governed KMS key when required by the data classification.", [resource.address])
}
