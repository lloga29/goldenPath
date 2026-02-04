# Módulo Object Storage

Almacenamiento de objetos cloud-agnostic (S3, Blob Storage, GCS).

## Uso

### AWS S3

```hcl
module "s3_bucket" {
  source = "git::https://github.com/org/terraform-modules.git//modules/storage/object-storage?ref=v1.0.0"

  name           = "mi-app-data-prod"
  environment    = "prod"
  cloud_provider = "aws"

  versioning_enabled    = true
  encryption_enabled    = true
  public_access_blocked = true

  lifecycle_rules = [
    {
      id                       = "archive-old-data"
      enabled                  = true
      prefix                   = "logs/"
      expiration_days          = 365
      transition_days          = 90
      transition_storage_class = "GLACIER"
    }
  ]

  tags = {
    Team       = "platform"
    CostCenter = "cc-001"
  }
}
```

### GCP Cloud Storage

```hcl
module "gcs_bucket" {
  source = "git::https://github.com/org/terraform-modules.git//modules/storage/object-storage?ref=v1.0.0"

  name           = "mi-app-data-prod"
  environment    = "prod"
  cloud_provider = "gcp"
  project_id     = "mi-proyecto"
  location       = "US"

  versioning_enabled    = true
  public_access_blocked = true

  tags = {
    Team       = "platform"
    CostCenter = "cc-001"
  }
}
```

## Seguridad

- Encriptación habilitada por defecto
- Acceso público bloqueado por defecto
- Versionamiento habilitado por defecto
- Lifecycle rules para gestión de costos
