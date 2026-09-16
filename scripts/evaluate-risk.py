#!/usr/bin/env python3
"""Derive a fail-closed R0-R4 GoldenPath assurance plan from Architecture as Code and change context."""
from __future__ import annotations
import argparse, hashlib, json, re, sys
from pathlib import Path

RISK_LEVELS=("R0","R1","R2","R3","R4")
RISK_INDEX={level:i for i,level in enumerate(RISK_LEVELS)}
AUTONOMY=("automated","policy-bounded","guarded","supervised","human-authorized")
SERVICE_TYPES={"documentation","application","api","worker","platform","data","infrastructure"}
DATA_SENSITIVITY={"public","internal","confidential","restricted"}
RUNTIMES={"none","serverless","managed-service","kubernetes","vm"}
SLO_TIERS={"none","tier3","tier2","tier1"}
DEPLOYMENT_UNITS={"none","package","container","function","helm","kustomize","terraform"}
CHANGE_TYPES={"docs","code","config","dependency","policy","architecture","infrastructure"}
GATE_RE=re.compile(r"^[a-z0-9][a-z0-9._-]{1,127}$")

class ValidationError(ValueError): pass

def fail(msg): raise ValidationError(msg)
def obj(v,p):
    if not isinstance(v,dict): fail(f"{p} must be an object")
    return v
def arr(v,p):
    if not isinstance(v,list): fail(f"{p} must be an array")
    return v
def text(v,p):
    if not isinstance(v,str) or not v: fail(f"{p} must be a non-empty string")
    return v
def boolean(v,p):
    if not isinstance(v,bool): fail(f"{p} must be a boolean")
    return v
def keys(v,required,allowed,p):
    missing=sorted(required-v.keys())
    if missing: fail(f"{p} is missing required keys: {', '.join(missing)}")
    unknown=sorted(v.keys()-allowed)
    if unknown: fail(f"{p} contains unknown keys: {', '.join(unknown)}")
def canonical_digest(v):
    raw=json.dumps(v,sort_keys=True,separators=(",",":"),ensure_ascii=False).encode()
    return "sha256:"+hashlib.sha256(raw).hexdigest()
def unique_strings(v,p,allow_empty=True):
    items=arr(v,p)
    if not allow_empty and not items: fail(f"{p} must not be empty")
    out=[]
    for i,item in enumerate(items): out.append(text(item,f"{p}[{i}]"))
    if len(out)!=len(set(out)): fail(f"{p} must not contain duplicates")
    return out

def validate_architecture(value):
    a=obj(value,"architecture")
    keys(a,{"schemaVersion","service"},{"schemaVersion","service"},"architecture")
    if a["schemaVersion"]!="goldenpath.architecture/v1": fail("architecture.schemaVersion must be goldenpath.architecture/v1")
    s=obj(a["service"],"architecture.service")
    req={"name","owner","serviceType","dataSensitivity","dependencies","runtime","sloTier","deploymentUnit","riskClass"}
    keys(s,req,req,"architecture.service")
    for k in ("name","owner"): text(s[k],f"architecture.service.{k}")
    enums={"serviceType":SERVICE_TYPES,"dataSensitivity":DATA_SENSITIVITY,"runtime":RUNTIMES,"sloTier":SLO_TIERS,"deploymentUnit":DEPLOYMENT_UNITS,"riskClass":set(RISK_LEVELS)}
    for k,allowed in enums.items():
        v=text(s[k],f"architecture.service.{k}")
        if v not in allowed: fail(f"architecture.service.{k} must be one of {sorted(allowed)}")
    unique_strings(s["dependencies"],"architecture.service.dependencies")
    return s

def validate_change(value):
    c=obj(value,"change")
    req={"changeType","touchesProduction","changesPolicy","changesArchitecture","changesDesiredState","changesIdentity","changesNetwork","changesData"}
    keys(c,req,req,"change")
    t=text(c["changeType"],"change.changeType")
    if t not in CHANGE_TYPES: fail(f"change.changeType must be one of {sorted(CHANGE_TYPES)}")
    for k in req-{"changeType"}: boolean(c[k],f"change.{k}")
    return c

def validate_controls(c,p):
    c=obj(c,p); req={"requiredGates","requiredReviewerRoles","previewEnvironmentRequired","runtimeValidationRequired","humanApprovalGateIds","autonomy"}; keys(c,req,req,p)
    gates=unique_strings(c["requiredGates"],f"{p}.requiredGates",False)
    for gate in gates:
        if not GATE_RE.fullmatch(gate): fail(f"{p}.requiredGates contains invalid gate id {gate}")
    reviewers=unique_strings(c["requiredReviewerRoles"],f"{p}.requiredReviewerRoles",False)
    approvals=unique_strings(c["humanApprovalGateIds"],f"{p}.humanApprovalGateIds")
    for gate in approvals:
        if gate not in gates: fail(f"{p}.humanApprovalGateIds must be a subset of requiredGates")
    preview=boolean(c["previewEnvironmentRequired"],f"{p}.previewEnvironmentRequired")
    runtime=boolean(c["runtimeValidationRequired"],f"{p}.runtimeValidationRequired")
    if preview and "preview-environment" not in gates: fail(f"{p} requires preview but omits preview-environment gate")
    autonomy=text(c["autonomy"],f"{p}.autonomy")
    if autonomy not in AUTONOMY: fail(f"{p}.autonomy must be one of {AUTONOMY}")
    return {"requiredGates":gates,"requiredReviewerRoles":reviewers,"previewEnvironmentRequired":preview,"runtimeValidationRequired":runtime,"humanApprovalGateIds":approvals,"autonomy":autonomy}

def validate_policy(value):
    p=obj(value,"policy"); keys(p,{"schemaVersion","globalMinimum","levels"},{"schemaVersion","globalMinimum","levels"},"policy")
    if p["schemaVersion"]!="goldenpath.risk-policy/v1": fail("policy.schemaVersion must be goldenpath.risk-policy/v1")
    g=obj(p["globalMinimum"],"policy.globalMinimum"); keys(g,{"requiredGates","requiredReviewerRoles"},{"requiredGates","requiredReviewerRoles"},"policy.globalMinimum")
    global_gates=set(unique_strings(g["requiredGates"],"policy.globalMinimum.requiredGates",False)); global_reviewers=set(unique_strings(g["requiredReviewerRoles"],"policy.globalMinimum.requiredReviewerRoles",False))
    levels=obj(p["levels"],"policy.levels")
    if set(levels)!=set(RISK_LEVELS): fail("policy.levels must define exactly R0 through R4")
    validated={level:validate_controls(levels[level],f"policy.levels.{level}") for level in RISK_LEVELS}
    previous=None
    for idx,level in enumerate(RISK_LEVELS):
        c=validated[level]
        if not global_gates.issubset(c["requiredGates"]): fail(f"{level} removes a global minimum gate")
        if not global_reviewers.issubset(c["requiredReviewerRoles"]): fail(f"{level} removes a global minimum reviewer role")
        if c["autonomy"]!=AUTONOMY[idx]: fail(f"{level}.autonomy must be {AUTONOMY[idx]} to preserve the reference monotonicity contract")
        if previous:
            for field in ("requiredGates","requiredReviewerRoles","humanApprovalGateIds"):
                if not set(previous[field]).issubset(c[field]): fail(f"{level} removes lower-tier {field}")
            if previous["previewEnvironmentRequired"] and not c["previewEnvironmentRequired"]: fail(f"{level} cannot remove preview requirement")
            if previous["runtimeValidationRequired"] and not c["runtimeValidationRequired"]: fail(f"{level} cannot remove runtime validation")
        previous=c
    return validated

def classify(service,change):
    signals=[]
    def signal(level,reason): signals.append((RISK_INDEX[level],level,reason))
    signal(service["riskClass"],f"declared risk class {service['riskClass']}")
    maps={
      "serviceType":{"documentation":"R0","application":"R1","api":"R1","worker":"R1","platform":"R2","data":"R2","infrastructure":"R3"},
      "dataSensitivity":{"public":"R0","internal":"R1","confidential":"R2","restricted":"R3"},
      "runtime":{"none":"R0","serverless":"R1","managed-service":"R1","kubernetes":"R2","vm":"R2"},
      "sloTier":{"none":"R0","tier3":"R1","tier2":"R2","tier1":"R3"},
      "deploymentUnit":{"none":"R0","package":"R1","container":"R1","function":"R1","helm":"R2","kustomize":"R2","terraform":"R3"},
      "changeType":{"docs":"R0","code":"R1","config":"R1","dependency":"R1","policy":"R2","architecture":"R2","infrastructure":"R3"}
    }
    for field in ("serviceType","dataSensitivity","runtime","sloTier","deploymentUnit"):
        signal(maps[field][service[field]],f"{field}={service[field]}")
    signal(maps["changeType"][change["changeType"]],f"changeType={change['changeType']}")
    n=len(service["dependencies"]); signal("R0" if n==0 else "R1" if n<=3 else "R2" if n<=9 else "R3",f"dependencies={n}")
    flag_levels={"changesPolicy":"R2","changesArchitecture":"R2","changesDesiredState":"R2","changesIdentity":"R3","changesNetwork":"R3","changesData":"R3","touchesProduction":"R4"}
    for flag,level in flag_levels.items():
        if change[flag]: signal(level,f"{flag}=true")
    top=max(i for i,_,_ in signals); level=RISK_LEVELS[top]
    reasons=[reason for i,_,reason in signals if i==top]
    return level,reasons

def build_plan(payload,policy):
    root=obj(payload,"input"); keys(root,{"architecture","change"},{"architecture","change"},"input")
    service=validate_architecture(root["architecture"]); change=validate_change(root["change"]); levels=validate_policy(policy)
    risk,reasons=classify(service,change); controls=levels[risk]
    architecture_digest=canonical_digest(root["architecture"]); policy_digest=canonical_digest(policy)
    plan_core={"schemaVersion":"goldenpath.assurance/v1","riskLevel":risk,"architecture":{"service":service["name"],"owner":service["owner"],"metadataDigest":architecture_digest},"inputs":{"declaredRiskClass":service["riskClass"],"derivedSignals":reasons,"policyDigest":policy_digest},"controls":controls}
    evidence_core={"schemaVersion":"goldenpath.assurance/v1","riskLevel":risk,"policyDigest":policy_digest,"architectureMetadataDigest":architecture_digest,"requiredGateIds":controls["requiredGates"],"runtimeValidationRequired":controls["runtimeValidationRequired"],"previewEnvironmentRequired":controls["previewEnvironmentRequired"],"humanApprovalGateIds":controls["humanApprovalGateIds"],"autonomy":controls["autonomy"]}
    plan_digest=canonical_digest(evidence_core)
    evidence={**evidence_core,"planDigest":plan_digest}
    return {**plan_core,"evidenceRequirements":evidence}

def load(path):
    try: return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError: fail(f"file does not exist: {path}")
    except json.JSONDecodeError as e: fail(f"invalid JSON in {path}: {e}")
def main():
    ap=argparse.ArgumentParser(description=__doc__); ap.add_argument("input",type=Path); ap.add_argument("--policy",type=Path,default=Path("platform-assurance/risk/policy/r0-r4-policy.json")); ap.add_argument("--output",type=Path); args=ap.parse_args()
    try: plan=build_plan(load(args.input),load(args.policy))
    except ValidationError as e: print(f"ERROR: {e}",file=sys.stderr); return 1
    rendered=json.dumps(plan,indent=2)+"\n"
    if args.output: args.output.write_text(rendered,encoding="utf-8")
    else: print(rendered,end="")
    return 0
if __name__=="__main__": raise SystemExit(main())
