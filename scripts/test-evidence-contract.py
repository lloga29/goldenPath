#!/usr/bin/env python3
"""Regression-test the GoldenPath Evidence Manifest contract and fail-closed semantics."""
from __future__ import annotations
import json, subprocess, sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]; VALIDATOR=ROOT/"scripts"/"validate-evidence-manifest.py"; SCHEMA=ROOT/"platform-assurance"/"evidence"/"schema"/"goldenpath-evidence-v1.schema.json"; FIXTURES=ROOT/"platform-assurance"/"evidence"/"fixtures"
CASES={"valid-reference.json":0,"valid-runtime.json":0,"valid-risk-adaptive.json":0,"invalid-required-gate-ready.json":1,"invalid-runtime-without-proof.json":1,"invalid-skip-not-allowed.json":1,"invalid-source-drift.json":1,"invalid-risk-missing-gate.json":1}
def check_schema_contract():
    s=json.loads(SCHEMA.read_text(encoding="utf-8"))
    if s.get("$schema")!="https://json-schema.org/draft/2020-12/schema": raise RuntimeError("Evidence schema must declare JSON Schema draft 2020-12")
    if s.get("properties",{}).get("schemaVersion",{}).get("const")!="goldenpath.evidence/v1": raise RuntimeError("Evidence schema version does not match goldenpath.evidence/v1")
    gate_results=s.get("$defs",{}).get("gateEvidence",{}).get("properties",{}).get("result",{}).get("enum",[]); expected={"PASS","FAIL","INFRASTRUCTURE_FAILURE","SKIP_ALLOWED"}
    if set(gate_results)!=expected: raise RuntimeError(f"Gate result taxonomy drifted: expected {sorted(expected)}, got {gate_results}")
    if s.get("$defs",{}).get("assuranceSnapshot",{}).get("properties",{}).get("schemaVersion",{}).get("const")!="goldenpath.assurance/v1": raise RuntimeError("Evidence schema must bind goldenpath.assurance/v1")
def run_case(filename,expected_status):
    r=subprocess.run([sys.executable,str(VALIDATOR),str(FIXTURES/filename)],text=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    actual=0 if r.returncode==0 else 1
    if actual!=expected_status:
        raise RuntimeError(f"{filename}: expected normalized exit {expected_status}, got {r.returncode}\nstdout:\n{r.stdout}\nstderr:\n{r.stderr}")
def check_expected_commit_invalidation():
    manifest=FIXTURES/"valid-reference.json"; valid="1111111111111111111111111111111111111111"; stale="9999999999999999999999999999999999999999"
    fresh=subprocess.run([sys.executable,str(VALIDATOR),str(manifest),"--expected-commit",valid],stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
    if fresh.returncode!=0: raise RuntimeError(f"Expected-commit positive test failed: {fresh.stderr}")
    stale_result=subprocess.run([sys.executable,str(VALIDATOR),str(manifest),"--expected-commit",stale],stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
    if stale_result.returncode==0: raise RuntimeError("Stale evidence unexpectedly passed --expected-commit validation")
def main():
    check_schema_contract()
    for f,e in CASES.items(): run_case(f,e)
    check_expected_commit_invalidation(); print(f"PASS: evidence contract regression suite ({len(CASES)} fixtures + stale-commit check)"); return 0
if __name__=="__main__": raise SystemExit(main())
