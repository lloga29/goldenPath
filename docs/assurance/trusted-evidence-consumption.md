# Trusted Evidence Consumption

GoldenPath separates Evidence Manifest contract validation from trusted evidence consumption.

`scripts/validate-evidence-manifest.py` validates the structure, fail-closed gate semantics, source binding, runtime requirements, and optional R0-R4 assurance snapshot of a manifest. A manifest can still be validated in isolation because fixtures, producers, and offline tooling need that capability.

`scripts/verify-evidence-input-digests.py` is the stricter consumer path. It requires the consumer to provide authoritative policy, Architecture as Code, and desired-state sources. It recomputes all three digests before invoking the Evidence Manifest validator. A producer-supplied digest is therefore not accepted merely because it is well formed.

## Authoritative inputs

The consumer requires:

- `--policy-source`: a `goldenpath.risk-policy/v1` JSON document;
- `--architecture-source`: a `goldenpath.architecture/v1` JSON document, or a JSON document that contains it under `architecture`;
- `--desired-state-source`: a regular file or directory representing the desired state being assessed.

Policy and architecture use the same canonical JSON SHA-256 algorithm as the R0-R4 assurance engine: keys are sorted, separators are normalized, and UTF-8 JSON is hashed without presentation whitespace.

Desired state uses a deterministic filesystem digest. Regular files are ordered by relative POSIX path and each path/content pair is length framed before hashing. Relative paths therefore participate in identity, not only bytes. `.git` metadata is excluded. Empty desired-state inputs, symlinks, unsupported filesystem entries, unreadable files, and missing sources fail closed.

The consumer does not decide where authoritative inputs come from. A delivery system remains responsible for materializing the correct policy, architecture metadata, and desired state from its governed source before invoking the consumer.

## Usage

For assurance-bearing evidence, derive the authoritative plan digest independently and validate all current inputs:

```bash
PLAN_DIGEST="$(python3 scripts/evaluate-risk.py \
  platform-assurance/risk/examples/r2-change.json \
  | python3 -c 'import json,sys; print(json.load(sys.stdin)["evidenceRequirements"]["planDigest"])')"

python3 scripts/verify-evidence-input-digests.py \
  path/to/evidence.json \
  --policy-source platform-assurance/risk/policy/r0-r4-policy.json \
  --architecture-source path/to/architecture-and-change.json \
  --desired-state-source path/to/rendered-or-governed-desired-state \
  --expected-commit "$GITHUB_SHA" \
  --expected-plan-digest "$PLAN_DIGEST"
```

For evidence without an assurance snapshot, omit `--expected-plan-digest`. `--expected-commit` remains strongly recommended whenever the consumer knows the source revision it is evaluating.

## Fail-closed behavior

Trusted consumption rejects evidence when:

- the manifest digest differs from the current policy source;
- the manifest architecture digest differs from current Architecture as Code;
- the desired state changes in path or content;
- any authoritative source is missing or invalid;
- desired state is empty, symlinked, unreadable, or contains unsupported filesystem entries;
- the underlying Evidence Manifest contract rejects the manifest;
- the expected commit or expected assurance-plan digest does not match.

This is repository/reference evidence. Recomputing authoritative input digests does not create Kubernetes, cloud, runtime, or production evidence.
