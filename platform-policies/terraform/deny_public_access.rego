# Prevent unintended public exposure for supported AWS, Azure, and Google Cloud resources.
package terraform.public_access

import rego.v1

sensitive_ports := {22, 3389, 3306, 5432, 27017, 6379, 9200, 11211}

public_cidr(cidr) if {
    cidr in ["0.0.0.0/0", "::/0"]
}

sensitive_port_in_range(from_port, to_port) if {
    port := sensitive_ports[_]
    from_port <= port
    to_port >= port
}

port_spec_exposes_sensitive(spec) if {
    spec == "*"
}

port_spec_exposes_sensitive(spec) if {
    is_number(spec)
    spec in sensitive_ports
}

port_spec_exposes_sensitive(spec) if {
    is_string(spec)
    regex.match(`^[0-9]+$`, spec)
    port := to_number(spec)
    port in sensitive_ports
}

port_spec_exposes_sensitive(spec) if {
    is_string(spec)
    regex.match(`^[0-9]+-[0-9]+$`, spec)
    parts := split(spec, "-")
    sensitive_port_in_range(to_number(parts[0]), to_number(parts[1]))
}

azure_public_source(prefix) if {
    prefix in ["*", "Internet", "0.0.0.0/0", "::/0"]
}

azure_rule_public_source(after) if {
    azure_public_source(object.get(after, "source_address_prefix", ""))
}

azure_rule_public_source(after) if {
    prefix := object.get(after, "source_address_prefixes", [])[_]
    azure_public_source(prefix)
}

azure_rule_sensitive_port(after) if {
    port_spec_exposes_sensitive(object.get(after, "destination_port_range", ""))
}

azure_rule_sensitive_port(after) if {
    port := object.get(after, "destination_port_ranges", [])[_]
    port_spec_exposes_sensitive(port)
}

gcp_firewall_allows(firewall) if {
    allow := object.get(firewall, "allow", [])[_]
    protocol := lower(object.get(allow, "protocol", ""))
    protocol in ["all", "tcp"]
    ports := object.get(allow, "ports", [])
    count(ports) == 0
}

gcp_firewall_allows(firewall) if {
    allow := object.get(firewall, "allow", [])[_]
    protocol := lower(object.get(allow, "protocol", ""))
    protocol in ["all", "tcp"]
    port := object.get(allow, "ports", [])[_]
    port_spec_exposes_sensitive(port)
}

same_resource_identity(left, right) if {
    object.get(left, "module_address", "") == object.get(right, "module_address", "")
    left.name == right.name
    object.get(left, "index", "") == object.get(right, "index", "")
}

same_bucket_reference(bucket, companion) if {
    bucket_name := object.get(bucket.change.after, "bucket", "")
    bucket_name != ""
    object.get(companion.change.after, "bucket", "") == bucket_name
}

same_bucket_reference(bucket, companion) if {
    same_resource_identity(bucket, companion)
}

s3_public_access_block(bucket) if {
    companion := input.resource_changes[_]
    companion.type == "aws_s3_bucket_public_access_block"
    same_bucket_reference(bucket, companion)
}

s3_public_access_block_is_secure(block) if {
    block.block_public_acls == true
    block.block_public_policy == true
    block.ignore_public_acls == true
    block.restrict_public_buckets == true
}

# AWS
violations contains {"resource": resource.address, "msg": msg} if {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket"
    resource.change.actions[_] in ["create", "update"]
    acl := object.get(resource.change.after, "acl", "private")
    acl in ["public-read", "public-read-write", "authenticated-read"]
    msg := sprintf("S3 bucket '%s' must not use public ACL '%s'.", [resource.address, acl])
}

violations contains {"resource": resource.address, "msg": msg} if {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket"
    resource.change.actions[_] in ["create", "update"]
    not s3_public_access_block(resource)
    msg := sprintf("S3 bucket '%s' must have a matching aws_s3_bucket_public_access_block resource.", [resource.address])
}

violations contains {"resource": resource.address, "msg": msg} if {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket_public_access_block"
    resource.change.actions[_] in ["create", "update"]
    not s3_public_access_block_is_secure(resource.change.after)
    msg := sprintf("S3 public access block '%s' must enable all four public-access protections.", [resource.address])
}

violations contains {"resource": resource.address, "msg": msg} if {
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

violations contains {"resource": resource.address, "msg": msg} if {
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

violations contains {"resource": resource.address, "msg": msg} if {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    resource.change.actions[_] in ["create", "update"]
    object.get(resource.change.after, "publicly_accessible", false) == true
    msg := sprintf("RDS instance '%s' must not be publicly accessible.", [resource.address])
}

violations contains {"resource": resource.address, "msg": msg} if {
    resource := input.resource_changes[_]
    resource.type == "aws_redshift_cluster"
    resource.change.actions[_] in ["create", "update"]
    object.get(resource.change.after, "publicly_accessible", false) == true
    msg := sprintf("Redshift cluster '%s' must not be publicly accessible.", [resource.address])
}

# Azure
violations contains {"resource": resource.address, "msg": msg} if {
    resource := input.resource_changes[_]
    resource.type == "azurerm_storage_container"
    resource.change.actions[_] in ["create", "update"]
    access := lower(object.get(resource.change.after, "container_access_type", "private"))
    access != "private"
    msg := sprintf("Azure Storage container '%s' must use container_access_type=private.", [resource.address])
}

violations contains {"resource": resource.address, "msg": msg} if {
    resource := input.resource_changes[_]
    resource.type == "azurerm_storage_account"
    resource.change.actions[_] in ["create", "update"]
    object.get(resource.change.after, "public_network_access_enabled", true) != false
    msg := sprintf("Azure Storage account '%s' must set public_network_access_enabled=false.", [resource.address])
}

violations contains {"resource": resource.address, "msg": msg} if {
    resource := input.resource_changes[_]
    resource.type == "azurerm_network_security_rule"
    resource.change.actions[_] in ["create", "update"]
    after := resource.change.after
    lower(object.get(after, "direction", "")) == "inbound"
    lower(object.get(after, "access", "")) == "allow"
    azure_rule_public_source(after)
    azure_rule_sensitive_port(after)
    msg := sprintf("Azure NSG rule '%s' exposes a sensitive inbound port to a public source.", [resource.address])
}

# Google Cloud
violations contains {"resource": resource.address, "msg": msg} if {
    resource := input.resource_changes[_]
    resource.type == "google_storage_bucket"
    resource.change.actions[_] in ["create", "update"]
    lower(object.get(resource.change.after, "public_access_prevention", "inherited")) != "enforced"
    msg := sprintf("Google Cloud Storage bucket '%s' must set public_access_prevention=enforced.", [resource.address])
}

violations contains {"resource": resource.address, "msg": msg} if {
    resource := input.resource_changes[_]
    resource.type == "google_compute_firewall"
    resource.change.actions[_] in ["create", "update"]
    source := object.get(resource.change.after, "source_ranges", [])[_]
    public_cidr(source)
    gcp_firewall_allows(resource.change.after)
    msg := sprintf("Google Cloud firewall '%s' exposes a sensitive TCP port to %s.", [resource.address, source])
}

deny contains msg if {
    result := violations[_]
    msg := result.msg
}
