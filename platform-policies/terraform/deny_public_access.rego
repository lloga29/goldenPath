# Política: Denegar acceso público
# Descripción: Prohibe la creación de recursos con acceso público
package terraform.security

import future.keywords.in

# Denegar buckets S3 públicos
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket"
    resource.change.after.acl == "public-read"
    msg := sprintf("S3 bucket '%s' no debe ser público", [resource.address])
}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket"
    resource.change.after.acl == "public-read-write"
    msg := sprintf("S3 bucket '%s' no debe tener ACL public-read-write", [resource.address])
}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket_public_access_block"
    resource.change.after.block_public_acls == false
    msg := sprintf("S3 bucket '%s' debe bloquear ACLs públicos", [resource.address])
}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket_public_access_block"
    resource.change.after.block_public_policy == false
    msg := sprintf("S3 bucket '%s' debe bloquear políticas públicas", [resource.address])
}

# Denegar 0.0.0.0/0 en security groups para puertos sensibles
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_security_group_rule"
    resource.change.after.type == "ingress"
    resource.change.after.cidr_blocks[_] == "0.0.0.0/0"
    sensitive_port(resource.change.after.from_port)
    msg := sprintf("Security group '%s' permite 0.0.0.0/0 en puerto sensible %v", 
                   [resource.address, resource.change.after.from_port])
}

# Puertos sensibles: SSH, RDP, bases de datos, caches
sensitive_port(port) {
    port in [22, 3389, 3306, 5432, 27017, 6379, 9200, 11211]
}

# Denegar RDS públicamente accesible
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    resource.change.after.publicly_accessible == true
    msg := sprintf("RDS instance '%s' no debe ser públicamente accesible", [resource.address])
}

# Denegar Redshift públicamente accesible
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_redshift_cluster"
    resource.change.after.publicly_accessible == true
    msg := sprintf("Redshift cluster '%s' no debe ser públicamente accesible", [resource.address])
}
