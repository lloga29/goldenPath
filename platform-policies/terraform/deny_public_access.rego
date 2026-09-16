# Prevent unintended public exposure for supported AWS resource types.
package terraform.security

import future.keywords.in

sensitive_ports := {22, 3389, 3306, 5432, 27017, 6379, 9200, 11211}

public_cidr(cidr) {
    cidr in ["0.0.0.0/0", "::/0"]
}

sensitive_port_in_range(from_port, to_port) {
    port := sensitive_ports[_]
    from_port <= port
    to_port >= port
}

same_resource_identity(left, right) {
    object.get(left, "module_address", "") == object.get(right, "module_address", "")
    left.name == right.name
    object.get(left, "index", "") == object.get(right, "index", "")
}

same_bucket_reference(bucket, companion) {
    bucket_name := object.get(bucket.change.after, "bucket", "")
    bucket_name != ""
    object.get(companion.change.after, "bucket", "") == bucket_name
}

same_bucket_reference(bucket, companion) {
    same_resource_identity(bucket, companion)
}

s3_public_access_block(bucket) {
    companion := input.resource_changes[_]
    companion.type == "aws_s3_bucket_public_access_block"
    same_bucket_reference(bucket, companion)
}

s3_public_access_block_is_secure(block) {
    block.block_public_acls == true
    block.block_public_policy == true
    block.ignore_public_acls == true
    block.restrict_public_buckets == true
}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket"
    resource.change.actions[_] in ["create", "update"]
    acl := object.get(resource.change.after, "acl", "private")
    acl in ["public-read", "public-read-write", "authenticated-read"]
    msg := sprintf("S3 bucket '%s' must not use public ACL '%s'.", [resource.address, acl])
}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket"
    resource.change.actions[_] in ["create", "update"]
    not s3_public_access_block(resource)
    msg := sprintf("S3 bucket '%s' must have a matching aws_s3_bucket_public_access_block resource.", [resource.address])
}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket_public_access_block"
    resource.change.actions[_] in ["create", "update"]
    not s3_public_access_block_is_secure(resource.change.after)
    msg := sprintf("S3 public access block '%s' must enable all four public-access protections.", [resource.address])
}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_security_group_rule"
    resource.change.actions[_] in ["create", "update"]
    resource.change.after.type == "ingress"
    cidrs := object.get(resource.change.after, "cidr_blocks", [])
    cidr := cidrs[_]
    public_cidr(cidr)
    sensitive_port_in_range(resource.change.after.from_port, resource.change.after.to_port)
    msg := sprintf("Security group rule '%s' exposes a sensitive port range (%v-%v) to %s.", [resource.address, resource.change.after.from_port, resource.change.after.to_port, cidr])
}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_security_group"
    resource.change.actions[_] in ["create", "update"]
    ingress := object.get(resource.change.after, "ingress", [])[_]
    cidrs := object.get(ingress, "cidr_blocks", [])
    cidr := cidrs[_]
    public_cidr(cidr)
    sensitive_port_in_range(ingress.from_port, ingress.to_port)
    msg := sprintf("Security group '%s' exposes a sensitive port range (%v-%v) to %s.", [resource.address, ingress.from_port, ingress.to_port, cidr])
}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    resource.change.actions[_] in ["create", "update"]
    object.get(resource.change.after, "publicly_accessible", false) == true
    msg := sprintf("RDS instance '%s' must not be publicly accessible.", [resource.address])
}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_redshift_cluster"
    resource.change.actions[_] in ["create", "update"]
    object.get(resource.change.after, "publicly_accessible", false) == true
    msg := sprintf("Redshift cluster '%s' must not be publicly accessible.", [resource.address])
}
