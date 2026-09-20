# GoldenPath CLI v1

Status: **P4 contract for GoldenPath v0.2.0**

The root `goldenpath` Python entry point is the supported v0.2.0 paved-road interface for a source checkout. Invoke it with `python3 goldenpath`. It composes the existing P0-P3 implementation and preserves fail-closed evidence semantics.

## Commands

- `python3 goldenpath doctor --scope all`
- `python3 goldenpath plan`
- `python3 goldenpath validate --artifact-dir PATH`
- `python3 goldenpath lab up --artifact-dir PATH --lab-id ID`
- `python3 goldenpath lab down --lab-id ID`
- `python3 goldenpath assure --artifact-dir PATH`
- `python3 goldenpath verify --artifact-dir PATH`
- `python3 goldenpath evidence show --artifact-dir PATH`

Place `--output json` before the command for the versioned `goldenpath.cli-output/v1` machine envelope. The schema is `platform-assurance/cli/schema/goldenpath-cli-output-v1.schema.json`. Human and machine output represent the same underlying command result.

## Supported path

The intended sequence is doctor, validate, lab up, assure, verify, then evidence show. `lab up` runs the bounded P1 lifecycle and verifies teardown; it does not leave a cluster running. Runtime Lab evidence remains ephemeral runtime evidence and never becomes a production claim.

`validate` records repository/reference checks for the exact source revision. `assure` reuses the P2 generator and retains the public verification material. `verify` reuses the independent P2 verifier and pins expected source, artifact, desired-state, policy-bundle, and cluster identities. The verification result is also bound to SHA-256 digests of the exact receipt and runtime-evidence files so a modified artifact cannot reuse an older passing result.

## Reports and scorecards

`evidence show` writes `assurance-report.txt` and `platform-scorecard.json`. Repository evidence is VERIFIED only when repository validation passed for the same source revision as the signed receipt. Runtime evidence is VERIFIED only after independent verification still binds the current receipt and runtime evidence. Production validation is always NOT_CLAIMED for the v0.2.0 Runtime Lab.

The scorecard is versioned as `goldenpath.platform-scorecard/v1` with schema `platform-assurance/cli/schema/goldenpath-platform-scorecard-v1.schema.json`. It deliberately has no synthetic percentage, weighted health value, or maturity score. Each row comes from an explicit signed control or current continuous-assurance state, and `aggregation` is `none`.

A receipt whose stated decision contradicts required control outcomes fails closed. Missing dependencies, malformed artifacts, lower-level validation failures, identity or signature failures, and stale verification bindings return a non-zero status with diagnostics; blocking conditions are never downgraded to advisory PASS.
