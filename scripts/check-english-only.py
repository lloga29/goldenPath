#!/usr/bin/env python3
"""Reject Spanish prose from repository text files."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SELF = Path(__file__).resolve()

# The checker is excluded because the detection vocabulary itself is data, not repository prose.
EXCLUDED_PATHS = {
    SELF,
}
EXCLUDED_PARTS = {".git"}
SPANISH_CHARACTERS = frozenset("áéíóúüñÁÉÍÓÚÜÑ¿¡")
SPANISH_WORDS = {
    "actualizacion",
    "actualizar",
    "administrador",
    "administradores",
    "aplicacion",
    "aplicaciones",
    "comandos",
    "configuracion",
    "crear",
    "creacion",
    "debe",
    "deben",
    "deberia",
    "deberian",
    "deshabilitado",
    "despliegue",
    "despliegues",
    "ejecucion",
    "ejecutar",
    "encriptacion",
    "entorno",
    "entornos",
    "equipo",
    "equipos",
    "habilitado",
    "habilitar",
    "instalacion",
    "instalar",
    "politica",
    "politicas",
    "prerrequisitos",
    "privilegiado",
    "privilegiados",
    "propietario",
    "propietarios",
    "publica",
    "publico",
    "recursos",
    "requerida",
    "requeridas",
    "requerido",
    "requeridos",
    "requiere",
    "requieren",
    "seguridad",
    "servicio",
    "servicios",
    "usar",
}
WORD_PATTERN = re.compile(
    r"\b(?:" + "|".join(sorted(map(re.escape, SPANISH_WORDS), key=len, reverse=True)) + r")\b",
    re.IGNORECASE,
)


def text_lines(path: Path) -> list[str] | None:
    data = path.read_bytes()
    if b"\x00" in data:
        return None
    try:
        return data.decode("utf-8").splitlines()
    except UnicodeDecodeError:
        return None


def scan() -> list[str]:
    findings: list[str] = []
    for path in sorted(ROOT.rglob("*")):
        if not path.is_file() or path in EXCLUDED_PATHS:
            continue
        if any(part in EXCLUDED_PARTS for part in path.parts):
            continue

        lines = text_lines(path)
        if lines is None:
            continue

        relative = path.relative_to(ROOT)
        for line_number, line in enumerate(lines, start=1):
            accented = sorted({char for char in line if char in SPANISH_CHARACTERS})
            words = sorted({match.group(0) for match in WORD_PATTERN.finditer(line)}, key=str.lower)
            if accented or words:
                reasons: list[str] = []
                if accented:
                    reasons.append("Spanish-specific character(s): " + " ".join(accented))
                if words:
                    reasons.append("Spanish token(s): " + ", ".join(words))
                findings.append(f"{relative}:{line_number}: {'; '.join(reasons)} :: {line.strip()}")
    return findings


def main() -> int:
    findings = scan()
    if findings:
        print("English-only repository check failed:", file=sys.stderr)
        for finding in findings:
            print(f"  {finding}", file=sys.stderr)
        print("Translate the prose to English. Do not suppress legitimate findings.", file=sys.stderr)
        return 1

    print("English-only repository check passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
