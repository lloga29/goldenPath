# Changelog

Todos los cambios notables en este proyecto serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/),
y este proyecto adhiere a [Semantic Versioning](https://semver.org/lang/es/).

## [0.1.0] - 2024-01-15

### Añadido
- Estructura inicial del repositorio
- Módulo `networking/vpc` - VPC cloud-agnostic (AWS/Azure/GCP)
- Módulo `security/iam-role` - Roles IAM para AWS
- Módulo `security/github-oidc` - Federación OIDC para GitHub Actions
- Módulo `storage/object-storage` - Almacenamiento de objetos cloud-agnostic
- Módulo `compute/kubernetes-cluster` - Cluster Kubernetes (EKS/AKS/GKE)
- Pattern `three-tier-app` - Arquitectura de 3 capas
- Workflows de CI/CD para validación y releases
- Documentación inicial y guías de contribución
- Pre-commit hooks configurados
- Tests unitarios con Terraform native testing

### Seguridad
- Validaciones de seguridad con Checkov y TFSec
- Políticas de tags obligatorios
- Encryption por defecto en todos los recursos
