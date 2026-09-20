# ADR-0010: Use Independently Verifiable Assurance Receipts

- Status: Accepted

## Context

A runtime run can emit many facts. Consumers need a compact result without trusting a producer-selected `PASS` label.

## Decision

GoldenPath will use `goldenpath.assurance-receipt/v1` as the v0.2 receipt contract.

A receipt repeats subject identities, binds the exact runtime-evidence object by canonical SHA-256 digest, carries required control outcomes, and derives its decision from those controls.

The generator and verifier are separate trust roles. Verification compares receipt identities to supplied runtime evidence and to independently expected identities when provided.

P2 will add cryptographic signing and signature verification without weakening the P0 identity/freshness rules.

## Consequences

- Tampering or identity mismatch fails before a receipt can be trusted.
- A historical receipt remains an immutable historical statement rather than a mutable current-state flag.
- Consumers can verify a receipt without rerunning the producer.
- Receipt signing can be added in P2 as an additional trust layer instead of redefining the contract.

