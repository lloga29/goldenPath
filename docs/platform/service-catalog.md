# Service Catalog Contract

A Golden Path benefits from a service catalog even when the organization has not yet selected a catalog product.

This repository defines the metadata contract but does not implement a catalog backend.

## Minimum service metadata

Each production service should expose or register:

- service ID and display name;
- owning team;
- repository;
- workload type;
- runtime environment(s);
- criticality/tier;
- on-call or escalation owner;
- SLO link;
- dashboards and alerts;
- runbook;
- data classification;
- upstream/downstream dependencies;
- API or event contracts when applicable;
- deployment/GitOps application;
- artifact registry location;
- lifecycle status.

## Why this matters

Ownership metadata connects technical automation to operations. Policy violations, vulnerability findings, cost anomalies, SLO alerts, certificate expiry, and deployment failures are much easier to route when a service has a canonical owner.

## Automation opportunities

The same metadata can drive namespace creation, dashboards, alert routing, RBAC, cost allocation, documentation links, scorecards, and platform adoption reporting.

## Source of truth

Choose one authoritative metadata source and synchronize outward. Do not maintain different team ownership values independently in Terraform tags, Kubernetes labels, CODEOWNERS, and an external catalog without a reconciliation strategy.
