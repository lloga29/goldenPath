#!/usr/bin/env python3
"""Exercise GoldenPath P4 CLI, reports, scorecards, and fail-closed diagnostics."""
from __future__ import annotations
import copy, json, os, subprocess, sys, tempfile
from datetime import datetime, timedelta, timezone
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
CLI=ROOT/"goldenpath"

def run(args,expected=0,env=None):
    result=subprocess.run([sys.executable,str(CLI),*args],cwd=ROOT,env=env,check=False,capture_output=True,text=True)
    if result.returncode!=expected:
        raise RuntimeError(f"CLI returned {result.returncode}, expected {expected}: {' '.join(args)}\nstdout:\n{result.stdout}\nstderr:\n{result.stderr}")
    return result

def payload(result):
    try: value=json.loads(result.stdout)
    except json.JSONDecodeError as exc: raise RuntimeError(f"CLI did not emit valid JSON:\n{result.stdout}") from exc
    if value.get("schemaVersion")!="goldenpath.cli-output/v1": raise RuntimeError("CLI output schema version changed")
    if value.get("productionValidation")!="NOT_CLAIMED": raise RuntimeError("CLI lost production evidence boundary")
    return value

def write_json(path,value): path.write_text(json.dumps(value,indent=2,sort_keys=True)+"\n",encoding="utf-8")
def iso(value): return value.astimezone(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00","Z")
def head(): return subprocess.run(["git","rev-parse","HEAD"],cwd=ROOT,check=True,capture_output=True,text=True).stdout.strip()

def main():
    if payload(run(["--output","json","doctor","--scope","repository"]))["status"]!="PASS":
        raise RuntimeError("repository doctor path should pass in CI")

    missing=os.environ.copy(); missing["PATH"]=""
    negative=payload(run(["--output","json","doctor","--scope","runtime"],expected=1,env=missing))
    if negative["status"]!="FAIL" or not negative["data"].get("missing"):
        raise RuntimeError("doctor did not fail closed on missing dependencies")

    with tempfile.TemporaryDirectory() as tmp:
        root=Path(tmp); plan_path=root/"plan.json"
        plan=payload(run(["--output","json","plan","--output-file",str(plan_path)]))
        if plan["status"]!="PASS" or not plan["data"].get("planDigest"): raise RuntimeError("plan did not expose versioned assurance identity")

        source=head(); observed=datetime.now(timezone.utc)-timedelta(seconds=5); digest="sha256:"+"1"*64; cluster="kind:p4-cli-contract-test"
        facts={
          "schemaVersion":"goldenpath.runtime-lab-facts/v1","evidenceTier":"runtime","environmentClass":"ephemeral-lab","productionValidation":"NOT_CLAIMED","observedAt":iso(observed),
          "execution":{"labId":"p4-cli-test-001","sourceRepository":"https://github.com/lloga29/goldenPath.git","sourceRevision":source},
          "runtime":{"clusterName":"gp-p4-cli-test-001","clusterIdentity":cluster,"namespace":"goldenpath-p4-cli-test-001","workloadUid":"11111111-2222-3333-4444-555555555555","podUid":"aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee","podPhase":"Running"},
          "artifact":{"expectedImage":f"localhost:5001/goldenpath-runtime@{digest}","expectedDigest":digest,"observedImage":f"localhost:5001/goldenpath-runtime@{digest}","observedImageId":f"docker-pullable://localhost:5001/goldenpath-runtime@{digest}"},
          "gitops":{"policyApplication":"gp-policies-p4-cli-test-001","workloadApplication":"gp-workload-p4-cli-test-001","desiredStateRevision":source,"reconciledRevision":source,"policyReconciledRevision":source,"syncStatus":"Synced","healthStatus":"Healthy"},
          "controls":{"admissionPolicyDenial":"PASS","runtimeDigestIdentity":"PASS","cleanupResidueCheck":"PASS"},
          "dependencies":{"kindNodeImage":"kindest/node:v1.37.0@sha256:"+"2"*64,"argoCD":"v3.5.3","gatekeeperChart":"3.23.1"},
        }
        write_json(root/"runtime-facts.json",facts)

        assure=payload(run(["--output","json","assure","--artifact-dir",str(root)]))
        if assure["status"]!="PASS" or assure["data"].get("decision")!="VERIFIED": raise RuntimeError("assure path failed")

        if payload(run(["--output","json","verify","--artifact-dir",str(root)]))["status"]!="PASS":
            raise RuntimeError("verify path failed")

        write_json(root/"repository-validation.json",{"schemaVersion":"goldenpath.repository-validation/v1","status":"PASS","sourceRevision":source,"evidenceTier":"repository","productionValidation":"NOT_CLAIMED","checks":[{"id":"p4-test","result":"PASS"}]})

        shown=payload(run(["--output","json","evidence","show","--artifact-dir",str(root)])); card=shown["data"]["scorecard"]
        if shown["status"]!="PASS" or card.get("aggregation")!="none": raise RuntimeError("scorecard status or aggregation is invalid")
        if card["evidence"]!={"repository":"VERIFIED","runtime":"VERIFIED","production":"NOT_CLAIMED"}:
            raise RuntimeError("scorecard evidence tiers are not correctly bound")

        human=run(["evidence","show","--artifact-dir",str(root)]).stdout
        for expected in ("GoldenPath Assurance Report","Repository Evidence","Runtime Evidence","Production Validation     NOT CLAIMED"):
            if expected not in human: raise RuntimeError(f"human report omitted {expected!r}")

        receipt_path=root/"assurance-receipt.json"; original=json.loads(receipt_path.read_text(encoding="utf-8"))
        contradicted=copy.deepcopy(original); contradicted["controls"][0]["result"]="FAIL"; write_json(receipt_path,contradicted)
        contradiction=payload(run(["--output","json","evidence","show","--artifact-dir",str(root)],expected=1))
        if "contradicts" not in contradiction["summary"]: raise RuntimeError("false VERIFIED decision did not fail closed")

        write_json(receipt_path,original)
        stale=json.loads((root/"verification-result.json").read_text(encoding="utf-8")); stale["receiptFileDigest"]="sha256:"+"0"*64; write_json(root/"verification-result.json",stale)
        stale_result=payload(run(["--output","json","evidence","show","--artifact-dir",str(root)],expected=1))
        if "does not bind" not in stale_result["summary"]: raise RuntimeError("stale verification was reused")

    print("PASS: P4 CLI provides versioned output, human reports, evidence-backed scorecards, official assure/verify composition, dependency diagnostics, and fail-closed negative paths")
    return 0

if __name__=="__main__": raise SystemExit(main())
