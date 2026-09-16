#!/usr/bin/env python3
"""Regression-test R0-R4 classification, monotonic controls, and fail-closed inputs."""
from __future__ import annotations
import copy
import importlib.util
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ENGINE = ROOT / "scripts" / "evaluate-risk.py"
POLICY = ROOT / "platform-assurance" / "risk" / "policy" / "r0-r4-policy.json"
FIXTURE = ROOT / "platform-assurance" / "risk" / "fixtures" / "r0-r4-cases.json"
ARCH_SCHEMA = ROOT / "platform-assurance" / "architecture" / "schema" / "goldenpath-architecture-v1.schema.json"
PLAN_SCHEMA = ROOT / "platform-assurance" / "risk" / "schema" / "goldenpath-assurance-v1.schema.json"

def load_module():
    spec = importlib.util.spec_from_file_location("risk_engine", ENGINE)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module

def check_schemas():
    architecture = json.loads(ARCH_SCHEMA.read_text(encoding="utf-8"))
    assurance = json.loads(PLAN_SCHEMA.read_text(encoding="utf-8"))
    if architecture.get("properties", {}).get("schemaVersion", {}).get("const") != "goldenpath.architecture/v1":
        raise RuntimeError("architecture schema version drift")
    if assurance.get("properties", {}).get("schemaVersion", {}).get("const") != "goldenpath.assurance/v1":
        raise RuntimeError("assurance schema version drift")

def main() -> int:
    module = load_module()
    policy = json.loads(POLICY.read_text(encoding="utf-8"))
    cases = json.loads(FIXTURE.read_text(encoding="utf-8"))
    check_schemas()
    module.validate_policy(policy)

    for expected, payload in cases["positive"].items():
        plan = module.build_plan(payload, policy)
        if plan["riskLevel"] != expected:
            raise RuntimeError(f"expected {expected}, got {plan['riskLevel']}")
        if plan["evidenceRequirements"]["requiredGateIds"] != plan["controls"]["requiredGates"]:
            raise RuntimeError(f"{expected}: evidence gate projection drift")
        if expected in {"R2", "R3", "R4"} and not plan["controls"]["runtimeValidationRequired"]:
            raise RuntimeError(f"{expected}: runtime validation unexpectedly disabled")
        evidence = plan["evidenceRequirements"]
        digest_input = {key: value for key, value in evidence.items() if key != "planDigest"}
        if evidence["planDigest"] != module.canonical_digest(digest_input):
            raise RuntimeError(f"{expected}: assurance requirements digest drift")

    try:
        module.build_plan(cases["negative"]["missingOwner"], policy)
    except module.ValidationError:
        pass
    else:
        raise RuntimeError("invalid architecture metadata unexpectedly passed")

    broken = copy.deepcopy(policy)
    broken["levels"]["R3"]["requiredGates"].remove("baseline-ci")
    try:
        module.validate_policy(broken)
    except module.ValidationError:
        pass
    else:
        raise RuntimeError("policy downgrade unexpectedly passed")

    declared_floor = copy.deepcopy(cases["positive"]["R0"])
    declared_floor["architecture"]["service"]["riskClass"] = "R4"
    if module.build_plan(declared_floor, policy)["riskLevel"] != "R4":
        raise RuntimeError("declared risk class was not treated as a floor")

    print("PASS: R0-R4 risk-adaptive assurance regression suite")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
