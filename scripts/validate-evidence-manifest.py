#!/usr/bin/env python3
"""Validate GoldenPath Evidence Manifest v1 using only the Python standard library."""
from __future__ import annotations
import argparse, json, re, sys
from datetime import datetime
from pathlib import Path
from urllib.parse import urlparse
SCHEMA_VERSION="goldenpath.evidence/v1"; ASSURANCE_VERSION="goldenpath.assurance/v1"
CLAIM_LEVELS={"implemented","reference","runtime-validated","production-validated"}; DECISIONS={"READY","NOT_READY"}; GATE_RESULTS={"PASS","FAIL","INFRASTRUCTURE_FAILURE","SKIP_ALLOWED"}; RUNTIME_RESULTS={"PASS","FAIL","INFRASTRUCTURE_FAILURE"}; ENVIRONMENTS={"repository","dev","staging","prod","ephemeral"}; RUNTIME_KINDS={"deployment","health","rollout","smoke","slo","rollback"}; RISK_LEVELS={"R0","R1","R2","R3","R4"}; AUTONOMY={"automated","policy-bounded","guarded","supervised","human-authorized"}
SHA_RE=re.compile(r"^[0-9a-f]{40}$"); DIGEST_RE=re.compile(r"^sha256:[0-9a-f]{64}$"); ID_RE=re.compile(r"^[a-z0-9][a-z0-9._-]{2,127}$"); GATE_ID_RE=re.compile(r"^[a-z0-9][a-z0-9._-]{1,127}$"); REPOSITORY_RE=re.compile(r"^[^/\s]+/[^/\s]+$")
class ValidationError(ValueError): pass
def fail(m): raise ValidationError(m)
def require_dict(v,p):
    if not isinstance(v,dict): fail(f"{p} must be an object")
    return v
def require_list(v,p):
    if not isinstance(v,list): fail(f"{p} must be an array")
    return v
def require_string(v,p):
    if not isinstance(v,str) or not v: fail(f"{p} must be a non-empty string")
    return v
def require_bool(v,p):
    if not isinstance(v,bool): fail(f"{p} must be a boolean")
    return v
def require_keys(o,k,p):
    m=sorted(k-o.keys())
    if m: fail(f"{p} is missing required keys: {', '.join(m)}")
def reject_unknown_keys(o,a,p):
    u=sorted(o.keys()-a)
    if u: fail(f"{p} contains unknown keys: {', '.join(u)}")
def validate_timestamp(v,p):
    t=require_string(v,p); c=t[:-1]+"+00:00" if t.endswith("Z") else t
    try: d=datetime.fromisoformat(c)
    except ValueError as e: fail(f"{p} must be an RFC3339-compatible timestamp: {e}")
    if d.tzinfo is None: fail(f"{p} must include a timezone offset or Z")
def validate_url(v,p):
    x=urlparse(require_string(v,p))
    if x.scheme not in {"http","https"} or not x.netloc: fail(f"{p} must be an absolute HTTP(S) URL")
def validate_sha(v,p):
    t=require_string(v,p)
    if not SHA_RE.fullmatch(t): fail(f"{p} must be a lowercase 40-character Git SHA")
    return t
def validate_digest(v,p):
    t=require_string(v,p)
    if not DIGEST_RE.fullmatch(t): fail(f"{p} must be a sha256:<64 lowercase hex> digest")
    return t
def validate_source(v):
    s=require_dict(v,"source"); require_keys(s,{"repository","commitSha"},"source"); reject_unknown_keys(s,{"repository","commitSha","workflowName","workflowRunUrl"},"source")
    if not REPOSITORY_RE.fullmatch(require_string(s["repository"],"source.repository")): fail("source.repository must use owner/name form")
    sha=validate_sha(s["commitSha"],"source.commitSha")
    if "workflowName" in s: require_string(s["workflowName"],"source.workflowName")
    if "workflowRunUrl" in s: validate_url(s["workflowRunUrl"],"source.workflowRunUrl")
    return sha
def validate_context(v):
    c=require_dict(v,"context"); require_keys(c,{"environment","capability"},"context"); reject_unknown_keys(c,{"environment","capability","service"},"context")
    e=require_string(c["environment"],"context.environment")
    if e not in ENVIRONMENTS: fail(f"context.environment must be one of {sorted(ENVIRONMENTS)}")
    require_string(c["capability"],"context.capability")
    if "service" in c: require_string(c["service"],"context.service")
    return e
def validate_inputs(v):
    x=require_dict(v,"inputs"); req={"sourceSha","policyDigest","architectureDigest","desiredStateDigest"}; require_keys(x,req,"inputs"); reject_unknown_keys(x,req,"inputs")
    s=validate_sha(x["sourceSha"],"inputs.sourceSha"); p=validate_digest(x["policyDigest"],"inputs.policyDigest"); a=validate_digest(x["architectureDigest"],"inputs.architectureDigest"); validate_digest(x["desiredStateDigest"],"inputs.desiredStateDigest"); return s,p,a
def validate_artifact(v):
    a=require_dict(v,"artifact"); require_keys(a,{"type","identity"},"artifact"); reject_unknown_keys(a,{"type","identity","digest"},"artifact"); t=require_string(a["type"],"artifact.type")
    if t not in {"container","package","bundle","none"}: fail("artifact.type must be container, package, bundle, or none")
    require_string(a["identity"],"artifact.identity")
    if "digest" in a: validate_digest(a["digest"],"artifact.digest")
    if t!="none" and "digest" not in a: fail("artifact.digest is required unless artifact.type is none")
def validate_gates(v):
    g=require_list(v,"gates")
    if not g: fail("gates must contain at least one gate")
    seen=set(); blocking=[]; by_id={}; allowed={"id","required","skipAllowed","result","observedAt","evidenceUrl","reason"}; req={"id","required","skipAllowed","result","observedAt"}
    for i,raw in enumerate(g):
        path=f"gates[{i}]"; gate=require_dict(raw,path); require_keys(gate,req,path); reject_unknown_keys(gate,allowed,path); gid=require_string(gate["id"],f"{path}.id")
        if not GATE_ID_RE.fullmatch(gid): fail(f"{path}.id has an invalid format")
        if gid in seen: fail(f"duplicate gate id: {gid}")
        seen.add(gid); required=require_bool(gate["required"],f"{path}.required"); skip=require_bool(gate["skipAllowed"],f"{path}.skipAllowed"); result=require_string(gate["result"],f"{path}.result")
        if result not in GATE_RESULTS: fail(f"{path}.result must be one of {sorted(GATE_RESULTS)}")
        validate_timestamp(gate["observedAt"],f"{path}.observedAt")
        if "evidenceUrl" in gate: validate_url(gate["evidenceUrl"],f"{path}.evidenceUrl")
        if "reason" in gate: require_string(gate["reason"],f"{path}.reason")
        if result=="SKIP_ALLOWED":
            if not skip: fail(f"{path} reports SKIP_ALLOWED but skipAllowed is false")
            if "reason" not in gate: fail(f"{path}.reason is required for SKIP_ALLOWED")
        if result in {"FAIL","INFRASTRUCTURE_FAILURE"} and "reason" not in gate: fail(f"{path}.reason is required for {result}")
        if required and not (result=="PASS" or (result=="SKIP_ALLOWED" and skip)): blocking.append(gid)
        by_id[gid]=gate
    return not blocking,blocking,by_id
def validate_runtime_evidence(v,required):
    r=require_list(v,"runtimeEvidence")
    if required and not r: fail("runtimeEvidence is required by the claim or assurance plan")
    ok=True; allowed={"kind","result","observedAt","evidenceUrl","reason"}; req={"kind","result","observedAt","evidenceUrl"}
    for i,raw in enumerate(r):
        p=f"runtimeEvidence[{i}]"; x=require_dict(raw,p); require_keys(x,req,p); reject_unknown_keys(x,allowed,p); k=require_string(x["kind"],f"{p}.kind")
        if k not in RUNTIME_KINDS: fail(f"{p}.kind must be one of {sorted(RUNTIME_KINDS)}")
        result=require_string(x["result"],f"{p}.result")
        if result not in RUNTIME_RESULTS: fail(f"{p}.result must be one of {sorted(RUNTIME_RESULTS)}")
        validate_timestamp(x["observedAt"],f"{p}.observedAt"); validate_url(x["evidenceUrl"],f"{p}.evidenceUrl")
        if "reason" in x: require_string(x["reason"],f"{p}.reason")
        if result!="PASS":
            ok=False
            if "reason" not in x: fail(f"{p}.reason is required for non-PASS runtime evidence")
    return ok
def string_list(v,p,nonempty=False):
    items=require_list(v,p)
    if nonempty and not items: fail(f"{p} must not be empty")
    out=[]
    for i,item in enumerate(items):
        s=require_string(item,f"{p}[{i}]")
        if not GATE_ID_RE.fullmatch(s): fail(f"{p}[{i}] has an invalid gate id")
        out.append(s)
    if len(out)!=len(set(out)): fail(f"{p} must not contain duplicates")
    return out
def validate_assurance(v,policy_digest,architecture_digest,gates):
    a=require_dict(v,"assurance"); req={"schemaVersion","riskLevel","policyDigest","planDigest","architectureMetadataDigest","requiredGateIds","runtimeValidationRequired","previewEnvironmentRequired","humanApprovalGateIds","autonomy"}; require_keys(a,req,"assurance"); reject_unknown_keys(a,req,"assurance")
    if require_string(a["schemaVersion"],"assurance.schemaVersion")!=ASSURANCE_VERSION: fail(f"assurance.schemaVersion must be {ASSURANCE_VERSION}")
    risk=require_string(a["riskLevel"],"assurance.riskLevel")
    if risk not in RISK_LEVELS: fail(f"assurance.riskLevel must be one of {sorted(RISK_LEVELS)}")
    if validate_digest(a["policyDigest"],"assurance.policyDigest")!=policy_digest: fail("assurance.policyDigest must match inputs.policyDigest")
    validate_digest(a["planDigest"],"assurance.planDigest")
    if validate_digest(a["architectureMetadataDigest"],"assurance.architectureMetadataDigest")!=architecture_digest: fail("assurance.architectureMetadataDigest must match inputs.architectureDigest")
    required=string_list(a["requiredGateIds"],"assurance.requiredGateIds",True); approvals=string_list(a["humanApprovalGateIds"],"assurance.humanApprovalGateIds")
    if not set(approvals).issubset(required): fail("assurance.humanApprovalGateIds must be a subset of requiredGateIds")
    runtime=require_bool(a["runtimeValidationRequired"],"assurance.runtimeValidationRequired"); preview=require_bool(a["previewEnvironmentRequired"],"assurance.previewEnvironmentRequired")
    if preview and "preview-environment" not in required: fail("preview assurance requires preview-environment in requiredGateIds")
    autonomy=require_string(a["autonomy"],"assurance.autonomy")
    if autonomy not in AUTONOMY: fail(f"assurance.autonomy must be one of {sorted(AUTONOMY)}")
    for gid in required:
        gate=gates.get(gid)
        if gate is None: fail(f"assurance-required gate is missing from evidence: {gid}")
        if gate["required"] is not True: fail(f"assurance-required gate must be marked required: {gid}")
    return runtime
def validate_manifest(data,expected_commit=None):
    m=require_dict(data,"manifest"); req={"schemaVersion","evidenceId","generatedAt","claimLevel","decision","source","context","inputs","gates"}; allowed=req|{"artifact","runtimeEvidence","assurance"}; require_keys(m,req,"manifest"); reject_unknown_keys(m,allowed,"manifest")
    if require_string(m["schemaVersion"],"schemaVersion")!=SCHEMA_VERSION: fail(f"schemaVersion must be {SCHEMA_VERSION}")
    if not ID_RE.fullmatch(require_string(m["evidenceId"],"evidenceId")): fail("evidenceId has an invalid format")
    validate_timestamp(m["generatedAt"],"generatedAt"); claim=require_string(m["claimLevel"],"claimLevel"); decision=require_string(m["decision"],"decision")
    if claim not in CLAIM_LEVELS: fail(f"claimLevel must be one of {sorted(CLAIM_LEVELS)}")
    if decision not in DECISIONS: fail(f"decision must be one of {sorted(DECISIONS)}")
    commit=validate_source(m["source"]); env=validate_context(m["context"]); source_sha,policy_digest,architecture_digest=validate_inputs(m["inputs"])
    if commit!=source_sha: fail("source.commitSha and inputs.sourceSha must match; evidence is invalidated by source drift")
    if expected_commit is not None:
        if not SHA_RE.fullmatch(expected_commit): fail("--expected-commit must be a lowercase 40-character Git SHA")
        if commit!=expected_commit: fail("manifest source commit does not match --expected-commit; evidence is stale")
    if "artifact" in m: validate_artifact(m["artifact"])
    gates_ready,blocking,gates=validate_gates(m["gates"])
    assurance_runtime=False
    if "assurance" in m: assurance_runtime=validate_assurance(m["assurance"],policy_digest,architecture_digest,gates)
    runtime_required=claim in {"runtime-validated","production-validated"} or assurance_runtime
    if runtime_required and "runtimeEvidence" not in m: fail("runtimeEvidence is required by the claim or assurance plan")
    runtime_ready=True
    if "runtimeEvidence" in m: runtime_ready=validate_runtime_evidence(m["runtimeEvidence"],runtime_required)
    if claim=="production-validated" and env!="prod": fail("production-validated evidence must target context.environment=prod")
    expected="READY" if gates_ready and (not runtime_required or runtime_ready) else "NOT_READY"
    if decision!=expected:
        details=f" blocking gates={blocking}" if blocking else ""; fail(f"decision must be derived from evidence: expected {expected}.{details}")
def load_json(path):
    try: return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError: fail(f"manifest does not exist: {path}")
    except json.JSONDecodeError as e: fail(f"manifest is not valid JSON: {e}")
def main():
    p=argparse.ArgumentParser(description=__doc__); p.add_argument("manifest",type=Path); p.add_argument("--expected-commit"); a=p.parse_args()
    try: validate_manifest(load_json(a.manifest),a.expected_commit)
    except ValidationError as e: print(f"ERROR: {e}",file=sys.stderr); return 1
    print(f"PASS: {a.manifest} satisfies {SCHEMA_VERSION}"); return 0
if __name__=="__main__": raise SystemExit(main())
