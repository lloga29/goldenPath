# Object Storage Reference Module

A multi-provider reference covering Amazon S3, an Azure Blob container, and Google Cloud Storage.

## Security defaults

The interface defaults to versioning enabled, encryption requested, and public access blocked. Provider implementations are not identical:

- **AWS:** the module configures bucket versioning, AES-256 server-side encryption, public-access blocking, and optional lifecycle rules.
- **Azure:** the current reference creates only a container in an **existing** Storage Account. Encryption, network restrictions, versioning, retention, and account-level security must be configured on that Storage Account outside this module.
- **Google Cloud:** the module enables uniform bucket-level access, optional object versioning, and public-access prevention. With no CMEK configured it relies on Google-managed encryption.

Do not interpret `encryption_enabled = true` as proof that equivalent customer-managed encryption is configured on every provider.

## AWS example

```hcl
module "object_storage" {
  source = "git::https://github.com/example/platform-terraform-modules.git//modules/storage/object-storage?ref=v1.0.0"

  name                  = "example-app-data-prod"
  environment           = "prod"
  cloud_provider        = "aws"
  versioning_enabled    = true
  encryption_enabled    = true
  public_access_blocked = true

  tags = {
    Team       = "platform"
    CostCenter = "cc-001"
  }
}
```

## Google Cloud example

```hcl
module "object_storage" {
  source = "git::https://github.com/example/platform-terraform-modules.git//modules/storage/object-storage?ref=v1.0.0"

  name                  = "example-app-data-prod"
  environment           = "prod"
  cloud_provider        = "gcp"
  project_id            = "example-prod"
  location              = "US"
  versioning_enabled    = true
  public_access_blocked = true

  tags = {
    Team       = "platform"
    CostCenter = "cc-001"
  }
}
```

Review deletion protection, retention, replication, backup, KMS/CMEK, access logging, network controls, and data-residency requirements before production use.
