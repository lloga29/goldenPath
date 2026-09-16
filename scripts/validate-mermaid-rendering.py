#!/usr/bin/env python3
"""Render every Mermaid Markdown fence and fail closed on invalid diagrams."""

from __future__ import annotations

import os
import re
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path

MERMAID_IMAGE = (
    "ghcr.io/mermaid-js/mermaid-cli/mermaid-cli@"
    "sha256:eddb559ae44da41de9e1adfa04687516de53c26016b258fd7ab35c9999313d7e"
)
OPEN_FENCE_RE = re.compile(r"^\s*(`{3,}|~{3,})\s*mermaid\s*$", re.IGNORECASE)


@dataclass(frozen=True)
class Diagram:
    source: Path
    start_line: int
    content: str


class MermaidValidationError(RuntimeError):
    """Raised when repository Mermaid validation cannot establish a trusted pass."""


def collect_diagrams(root: Path) -> list[Diagram]:
    diagrams: list[Diagram] = []
    for path in sorted(root.rglob("*.md")):
        if ".git" in path.parts:
            continue

        lines = path.read_text(encoding="utf-8").splitlines()
        index = 0
        while index < len(lines):
            match = OPEN_FENCE_RE.match(lines[index])
            if not match:
                index += 1
                continue

            fence = match.group(1)
            fence_char = fence[0]
            minimum_length = len(fence)
            start_line = index + 1
            body: list[str] = []
            index += 1

            while index < len(lines):
                stripped = lines[index].strip()
                if (
                    stripped
                    and set(stripped) == {fence_char}
                    and len(stripped) >= minimum_length
                ):
                    break
                body.append(lines[index])
                index += 1
            else:
                raise MermaidValidationError(
                    f"{path}:{start_line}: unterminated Mermaid fence"
                )

            content = "\n".join(body).strip()
            if not content:
                raise MermaidValidationError(
                    f"{path}:{start_line}: Mermaid fence is empty"
                )
            diagrams.append(Diagram(path, start_line, content + "\n"))
            index += 1

    return diagrams


def run_renderer(
    workdir: Path, input_name: str, output_name: str
) -> subprocess.CompletedProcess[str]:
    command = [
        "docker",
        "run",
        "--rm",
        "--network",
        "none",
        "--user",
        f"{os.getuid()}:{os.getgid()}",
        "--volume",
        f"{workdir}:/data",
        MERMAID_IMAGE,
        "-i",
        f"/data/{input_name}",
        "-o",
        f"/data/{output_name}",
    ]
    return subprocess.run(
        command,
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )


def prove_fail_closed(workdir: Path) -> None:
    canary_input = workdir / "invalid-canary.mmd"
    canary_output = workdir / "invalid-canary.svg"
    canary_input.write_text(
        "this is deliberately invalid Mermaid\n@@@\n", encoding="utf-8"
    )

    result = run_renderer(workdir, canary_input.name, canary_output.name)
    if result.returncode == 0:
        raise MermaidValidationError(
            "Mermaid canary unexpectedly rendered successfully; refusing to trust the renderer"
        )


def validate_render(workdir: Path, diagram: Diagram, ordinal: int) -> None:
    input_path = workdir / f"diagram-{ordinal:03d}.mmd"
    output_path = workdir / f"diagram-{ordinal:03d}.svg"
    input_path.write_text(diagram.content, encoding="utf-8")

    result = run_renderer(workdir, input_path.name, output_path.name)
    if result.returncode != 0:
        details = "\n".join(
            part for part in (result.stdout.strip(), result.stderr.strip()) if part
        )
        suffix = f"\n{details}" if details else ""
        raise MermaidValidationError(
            f"{diagram.source}:{diagram.start_line}: Mermaid render failed{suffix}"
        )

    if not output_path.is_file() or output_path.stat().st_size == 0:
        raise MermaidValidationError(
            f"{diagram.source}:{diagram.start_line}: renderer produced no SVG output"
        )

    rendered = output_path.read_text(encoding="utf-8", errors="replace")
    if "<svg" not in rendered:
        raise MermaidValidationError(
            f"{diagram.source}:{diagram.start_line}: renderer output is not SVG"
        )


def main() -> int:
    try:
        diagrams = collect_diagrams(Path("."))
        if not diagrams:
            raise MermaidValidationError(
                "no Mermaid diagrams found; validation scope may be broken"
            )

        with tempfile.TemporaryDirectory(prefix="goldenpath-mermaid-") as temp_dir:
            workdir = Path(temp_dir)
            prove_fail_closed(workdir)
            for ordinal, diagram in enumerate(diagrams, start=1):
                validate_render(workdir, diagram, ordinal)

        print(
            "Mermaid rendering validation passed: "
            f"{len(diagrams)} diagram(s) rendered with a digest-pinned, network-isolated CLI."
        )
        return 0
    except FileNotFoundError as exc:
        print(f"ERROR: required executable not found: {exc.filename}", file=sys.stderr)
    except MermaidValidationError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)

    return 1


if __name__ == "__main__":
    raise SystemExit(main())
