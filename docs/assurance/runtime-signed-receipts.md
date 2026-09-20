# Runtime Evidence and Signed Assurance Receipts

GoldenPath v0.2 P2 converts the raw Runtime Lab facts from P1 into identity-bound runtime evidence and a cryptographically signed assurance receipt. The supported path remains runtime evidence from an ephemeral lab; it does not create a production-validation claim.

## Trust model

The receipt uses Ed25519. The private signing key is never embedded in the receipt or uploaded as evidence. The receipt contains only the signing algorithm, a SHA-256 fingerprint identifying the public trust key, the SHA-256 digest of the canonical unsigned receipt payload, and the signature value.

Verification requires an independently supplied public key through `--trusted-public-key`. A public key carried only inside the same receipt would be self-asserted and is deliberately not trusted. For the Runtime Lab CI gate, an ephemeral Ed25519 key pair is created for the isolated run, the private key remains runner-local, and only the public key is retained with the evidence artifacts. This proves the signing and independent-verification path without pretending that the lab key is a production organizational root of trust.

A future production integration must replace the ephemeral lab signer with an explicitly governed external trust root such as an organization-controlled KMS/HSM or equivalent signer. That is outside the v0.2 Runtime Lab claim boundary.

## Signed payload

The signed payload is the canonical JSON representation of the assurance receipt with the top-level `signature` property omitted. Canonicalization uses UTF-8 JSON with sorted keys and compact separators. `signature.payloadDigest` is the SHA-256 digest of those exact canonical bytes.

The verifier fails closed when the signature is missing while `--require-signature` is requested, when the trusted key fingerprint differs, when the canonical payload digest differs, when base64 decoding fails, or when OpenSSL cannot verify the Ed25519 signature.

## Runtime collection

`scripts/generate-runtime-assurance.py` consumes:

- P1 `goldenpath.runtime-lab-facts/v1` facts;
- the applicable `goldenpath.assurance/v1` plan generated from `runtime-lab/assurance-input.json`;
- the exact source checkout;
- an Ed25519 private signing key.

The collector independently derives SHA-256 identities for the GitOps desired-state tree and the repository policy-bundle tree from `git ls-tree` at the exact source revision. It also requires the workload and policy Argo CD applications to report the exact source revision as reconciled, requires immutable workload digest equality, requires the P1 runtime controls to pass, and preserves `environmentClass: ephemeral-lab` plus `claim.tier: runtime`.

The generated files are:

- `runtime-evidence.json` — `goldenpath.runtime-evidence/v1`;
- `assurance-receipt.json` — `goldenpath.assurance-receipt/v1` plus Ed25519 signature metadata;
- `runtime-receipt-public.pem` — the run's public verification key;
- `assurance-summary.txt` — a human-readable view generated from the same receipt data.

## Independent verification

The supported verification pattern is:

```bash
python3 scripts/validate-runtime-assurance.py \
  assurance-receipt.json \
  --runtime-evidence runtime-evidence.json \
  --trusted-public-key runtime-receipt-public.pem \
  --require-signature \
  --expected-source <exact-source-sha> \
  --expected-artifact-digest <sha256:digest> \
  --expected-desired-state-revision <exact-gitops-sha> \
  --expected-policy-bundle-digest <sha256:digest> \
  --expected-cluster-identity <runtime-cluster-identity>
```

The expected identities are verifier inputs, not producer assertions. This is part of the replay and target-mismatch defense.

## Fail-closed adversarial gate

`scripts/test-runtime-assurance-p2.py` proves a valid signed receipt verifies and then exercises controlled mutations covering source revision, artifact digest, desired-state revision, policy-plan identity, runtime identity, required controls, signature bytes, runtime-evidence tampering, stale evidence, and replay against a mismatched expected source. Every mutation must fail.

The live Runtime Lab workflow performs the same signed generation and independent verification after P1 has completed its real Kubernetes lifecycle. Historical receipts remain evidence for their original bounded execution only; they are not proof of current or production state.
