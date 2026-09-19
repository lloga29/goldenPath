#!/usr/bin/env python3
"""Prove that the public evidence dashboard generator fails closed."""

from __future__ import annotations

import json
import subprocess
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
GENERATOR = ROOT / "scripts" / "generate-evidence-dashboard.py"
MANIFEST = ROOT / "platform-assurance" / "evidence" / "public-status.json"


def run(manifest: Path, output: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["python3", str(GENERATOR), str(manifest), str(output)],
        cwd=ROOT,
        text=True,
        capture_output=True,
        check=False,
    )


def expect_failure(data: dict, label: str, temp_dir: Path) -> None:
    manifest = temp_dir / f"{label}.json"
    output = temp_dir / f"{label}.html"
    manifest.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    result = run(manifest, output)
    if result.returncode == 0:
        raise SystemExit(f"ERROR: {label} unexpectedly passed")
    if output.exists():
        raise SystemExit(f"ERROR: {label} produced an output page despite failing")
    print(f"PASS: {label} rejected")


def main() -> int:
    canonical = json.loads(MANIFEST.read_text(encoding="utf-8"))

    with tempfile.TemporaryDirectory() as raw_temp_dir:
        temp_dir = Path(raw_temp_dir)

        positive_output = temp_dir / "positive.html"
        positive = run(MANIFEST, positive_output)
        if positive.returncode != 0 or not positive_output.is_file():
            print(positive.stdout)
            print(positive.stderr)
            raise SystemExit("ERROR: canonical public status manifest failed")
        print("PASS: canonical public status manifest accepted")

        missing_evidence = json.loads(json.dumps(canonical))
        missing_evidence["capabilities"][0]["evidence"].append(
            "does-not-exist/public-evidence.txt"
        )
        expect_failure(missing_evidence, "missing-evidence", temp_dir)

        runtime_claim = json.loads(json.dumps(canonical))
        runtime_claim["boundaries"]["runtime"] = "validated"
        expect_failure(runtime_claim, "runtime-claim", temp_dir)

        production_claim = json.loads(json.dumps(canonical))
        production_claim["boundaries"]["production"] = "validated"
        expect_failure(production_claim, "production-claim", temp_dir)

    print("PASS: public evidence dashboard fail-closed semantics verified")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
