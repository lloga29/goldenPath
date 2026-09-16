# Runbook: Cluster Recovery

## Trigger

Use when a Kubernetes cluster is lost, unrecoverable, or requires recreation as part of disaster recovery.

## Preconditions

Recovery requires access to infrastructure code/state, cloud identity, GitOps repositories, artifact registry, secret manager, DNS/certificates, and application data backups.

## Recovery sequence

1. Confirm the failure domain and whether recreating the cluster is safer than repair.
2. Restore or validate network and cloud foundation dependencies.
3. Recreate the cluster through the approved infrastructure path.
4. Configure cluster identity, baseline RBAC, storage classes, and network prerequisites.
5. Install/restore Argo CD securely.
6. Register repositories and cluster/project boundaries.
7. Reconcile platform add-ons in dependency order.
8. Restore secret synchronization.
9. Reconcile application namespaces/workloads.
10. Restore stateful application data according to application DR procedures.
11. Validate ingress, DNS, TLS, telemetry, policy enforcement, and alerts.

## Safety

Do not enable unrestricted automated sync until the desired Git state is confirmed safe. A cluster rebuild can reproduce a configuration incident if the Git source is still wrong.

## Exit criteria

Platform and application health meet recovery objectives, security controls are restored, telemetry is complete, and outstanding manual deviations are documented.
