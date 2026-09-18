# GoldenPath zero-cloud demo

The zero-cloud demo is the fastest way to see GoldenPath's risk-adaptive assurance and fail-closed evidence model without provisioning infrastructure or connecting to external services.

## Run it

From the repository root:

```bash
./scripts/demo.sh
```

Prerequisites:

- Bash;
- Python 3.

No cloud credentials, Docker daemon, Kubernetes cluster, Terraform installation, registry access, GitHub token, or third-party CLI is required.

## What the demo does

The script executes three repository/reference steps using the same implementation contracts exercised by CI.

### 1. Derive an R0-R4 assurance plan

`scripts/evaluate-risk.py` evaluates the reference Architecture as Code and change context in `platform-assurance/risk/examples/r2-change.json`.

The output includes:

- the derived risk level;
- the allowed autonomy mode;
- required assurance gates;
- the authoritative plan digest used to bind downstream evidence.

The demo prints those values instead of hard-coding a desired outcome.

### 2. Validate matching evidence

The demo validates `platform-assurance/evidence/fixtures/valid-risk-adaptive.json` with `scripts/validate-evidence-manifest.py` and requires its assurance snapshot to match the plan digest produced in step 1.

A successful result demonstrates that the evidence manifest is structurally valid and bound to the expected assurance plan.

### 3. Demonstrate fail-closed behavior

The demo then validates `platform-assurance/evidence/fixtures/invalid-risk-missing-gate.json`.

That fixture intentionally omits evidence required by the derived assurance plan. The validator must reject it. The demo treats rejection as the expected result and fails itself if the invalid evidence is ever accepted.

## What this proves

The demo provides repository/reference evidence that:

- deterministic inputs can derive risk-adaptive controls;
- evidence can be bound to an authoritative assurance plan;
- required evidence cannot be silently omitted while still producing a ready result;
- the public demo path is executable and is continuously exercised by repository CI.

## What this does not prove

The demo does **not** prove runtime or production behavior. It does not exercise:

- a real container registry or signature transparency service;
- a cloud account or infrastructure deployment;
- Argo CD reconciliation;
- a Kubernetes cluster;
- live workload health, rollout, SLO, or rollback evidence;
- production approval or incident procedures.

Those claims require their own runtime evidence or production validation.

## Go further

After the zero-cloud demo:

1. follow the [15-minute quickstart](QUICKSTART.md);
2. read the [risk-adaptive assurance model](assurance/risk-adaptive-assurance.md);
3. review the [evidence contract](assurance/evidence-contract.md);
4. review [trusted evidence consumption](assurance/trusted-evidence-consumption.md).
