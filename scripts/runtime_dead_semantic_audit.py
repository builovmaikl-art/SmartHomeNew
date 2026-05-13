#!/usr/bin/env python3
"""
Runtime dead semantic audit toolkit.

Purpose:
    Detect semantic entropy and dead runtime structures:
    - unused GVL fields;
    - unused DUT struct fields;
    - orphan DUT types;
    - compatibility zombie patterns.

IMPORTANT:
    Detect-only tool.
    No automatic deletion or rewriting is performed.

Usage:
    python3 scripts/runtime_dead_semantic_audit.py
    python3 scripts/runtime_dead_semantic_audit.py --summary
    python3 scripts/runtime_dead_semantic_audit.py --json

Reports:
    runtime_semantic_reports/latest/
    runtime_semantic_reports/history/
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable

INCLUDE_SUFFIXES = {".st", ".gvl", ".dut", ".typ"}

EXCLUDED_PARTS = {
    ".git",
    "archive",
    "archives",
    "generated",
    "docs",
    "runtime_verification_reports",
    "runtime_semantic_reports",
}

REPORT_DIR_DEFAULT = "runtime_semantic_reports"

ZOMBIE_PATTERNS = (
    "_Alarm_Active",
    "Legacy_",
    "Shadow_",
    "Compatibility_",
)


@dataclass(frozen=True)
class Finding:
    category: str
    severity: str
    symbol: str
    path: str
    line: int
    detail: str


@dataclass(frozen=True)
class Declaration:
    symbol: str
    path: str
    line: int
    kind: str


def utc_timestamp() -> str:
    return datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")


def iter_source_files(root: Path) -> Iterable[Path]:
    for path in root.rglob("*"):
        if not path.is_file():
            continue
        if path.suffix not in INCLUDE_SUFFIXES:
            continue
        rel_parts = set(path.relative_to(root).parts)
        if rel_parts & EXCLUDED_PARTS:
            continue
        yield path


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return path.read_text(encoding="utf-8", errors="replace")


def collect_all_text(root: Path) -> str:
    chunks: list[str] = []
    for path in iter_source_files(root):
        chunks.append(read_text(path))
    return "\n".join(chunks)


def collect_gvl_fields(root: Path) -> list[Declaration]:
    decls: list[Declaration] = []
    pattern = re.compile(r"^\s*(G_[A-Za-z0-9_]+)\s*:")

    for path in iter_source_files(root):
        if path.suffix != ".gvl":
            continue

        text = read_text(path)
        for line_no, line in enumerate(text.splitlines(), start=1):
            match = pattern.search(line)
            if not match:
                continue
            decls.append(
                Declaration(
                    symbol=match.group(1),
                    path=path.as_posix(),
                    line=line_no,
                    kind="GVL_FIELD",
                )
            )
    return decls


def collect_dut_fields(root: Path) -> list[Declaration]:
    decls: list[Declaration] = []
    pattern = re.compile(r"^\s*([A-Za-z][A-Za-z0-9_]*)\s*:")

    for path in iter_source_files(root):
        if path.suffix not in {".dut", ".typ"}:
            continue

        inside_struct = False
        text = read_text(path)

        for line_no, line in enumerate(text.splitlines(), start=1):
            stripped = line.strip().upper()

            if stripped == "STRUCT":
                inside_struct = True
                continue

            if stripped == "END_STRUCT":
                inside_struct = False
                continue

            if not inside_struct:
                continue

            match = pattern.search(line)
            if not match:
                continue

            field = match.group(1)

            if field in {"END_STRUCT"}:
                continue

            decls.append(
                Declaration(
                    symbol=field,
                    path=path.as_posix(),
                    line=line_no,
                    kind="DUT_FIELD",
                )
            )

    return decls


def collect_dut_types(root: Path) -> list[Declaration]:
    decls: list[Declaration] = []
    pattern = re.compile(r"^\s*TYPE\s+([A-Za-z0-9_]+)", re.IGNORECASE)

    for path in iter_source_files(root):
        if path.suffix not in {".dut", ".typ"}:
            continue

        text = read_text(path)
        for line_no, line in enumerate(text.splitlines(), start=1):
            match = pattern.search(line)
            if not match:
                continue

            decls.append(
                Declaration(
                    symbol=match.group(1),
                    path=path.as_posix(),
                    line=line_no,
                    kind="DUT_TYPE",
                )
            )

    return decls


def find_unused_gvl_fields(root: Path) -> list[Finding]:
    findings: list[Finding] = []
    all_text = collect_all_text(root)

    for decl in collect_gvl_fields(root):
        refs = len(re.findall(rf"\b{re.escape(decl.symbol)}\b", all_text))

        if refs <= 1:
            findings.append(
                Finding(
                    category="UNUSED_GVL_FIELD",
                    severity="WARN",
                    symbol=decl.symbol,
                    path=decl.path,
                    line=decl.line,
                    detail="GVL field appears declared but not referenced.",
                )
            )

    return findings


def find_unused_dut_fields(root: Path) -> list[Finding]:
    findings: list[Finding] = []
    all_text = collect_all_text(root)

    for decl in collect_dut_fields(root):
        refs = len(re.findall(rf"\.{re.escape(decl.symbol)}\b", all_text))

        if refs == 0:
            findings.append(
                Finding(
                    category="UNUSED_DUT_FIELD",
                    severity="WARN",
                    symbol=decl.symbol,
                    path=decl.path,
                    line=decl.line,
                    detail="DUT field appears unused.",
                )
            )

    return findings


def find_orphan_dut_types(root: Path) -> list[Finding]:
    findings: list[Finding] = []
    all_text = collect_all_text(root)

    for decl in collect_dut_types(root):
        refs = len(re.findall(rf"\b{re.escape(decl.symbol)}\b", all_text))

        if refs <= 1:
            findings.append(
                Finding(
                    category="ORPHAN_DUT_TYPE",
                    severity="WARN",
                    symbol=decl.symbol,
                    path=decl.path,
                    line=decl.line,
                    detail="DUT type appears declared but never instantiated/referenced.",
                )
            )

    return findings


def find_zombie_patterns(root: Path) -> list[Finding]:
    findings: list[Finding] = []

    for path in iter_source_files(root):
        text = read_text(path)

        for line_no, line in enumerate(text.splitlines(), start=1):
            for pattern in ZOMBIE_PATTERNS:
                if pattern not in line:
                    continue

                findings.append(
                    Finding(
                        category="SEMANTIC_ZOMBIE_PATTERN",
                        severity="INFO",
                        symbol=pattern,
                        path=path.as_posix(),
                        line=line_no,
                        detail="Potential compatibility/legacy semantic pattern detected.",
                    )
                )

    return findings


def summarize(findings: list[Finding]) -> dict[str, int]:
    summary = {
        "unused_gvl_fields": 0,
        "unused_dut_fields": 0,
        "orphan_dut_types": 0,
        "semantic_zombie_patterns": 0,
        "total_findings": len(findings),
    }

    for item in findings:
        if item.category == "UNUSED_GVL_FIELD":
            summary["unused_gvl_fields"] += 1
        elif item.category == "UNUSED_DUT_FIELD":
            summary["unused_dut_fields"] += 1
        elif item.category == "ORPHAN_DUT_TYPE":
            summary["orphan_dut_types"] += 1
        elif item.category == "SEMANTIC_ZOMBIE_PATTERN":
            summary["semantic_zombie_patterns"] += 1

    return summary


def write_reports(report: dict, report_dir: Path) -> None:
    latest = report_dir / "latest"
    history = report_dir / "history"

    latest.mkdir(parents=True, exist_ok=True)
    history.mkdir(parents=True, exist_ok=True)

    timestamp = report["started_at_utc"]

    summary_lines = [
        "Runtime dead semantic audit summary",
        "===================================",
        f"UNUSED_GVL_FIELDS: {report['summary']['unused_gvl_fields']}",
        f"UNUSED_DUT_FIELDS: {report['summary']['unused_dut_fields']}",
        f"ORPHAN_DUT_TYPES: {report['summary']['orphan_dut_types']}",
        f"SEMANTIC_ZOMBIE_PATTERNS: {report['summary']['semantic_zombie_patterns']}",
        f"TOTAL_FINDINGS: {report['summary']['total_findings']}",
    ]

    summary_text = "\n".join(summary_lines) + "\n"

    findings_text = "\n".join(
        f"[{f['category']}] {f['symbol']} @ {f['path']}:{f['line']} - {f['detail']}"
        for f in report["findings"]
    ) + "\n"

    json_text = json.dumps(report, ensure_ascii=False, indent=2) + "\n"

    latest_summary = latest / "runtime_dead_semantic_summary.txt"
    latest_log = latest / "runtime_dead_semantic_latest.log"
    latest_json = latest / "runtime_dead_semantic_latest.json"

    latest_summary.write_text(summary_text, encoding="utf-8")
    latest_log.write_text(summary_text + "\n" + findings_text, encoding="utf-8")
    latest_json.write_text(json_text, encoding="utf-8")

    shutil.copyfile(latest_summary, history / f"{timestamp}_runtime_dead_semantic_summary.txt")
    shutil.copyfile(latest_log, history / f"{timestamp}_runtime_dead_semantic.log")
    shutil.copyfile(latest_json, history / f"{timestamp}_runtime_dead_semantic.json")


def main() -> int:
    parser = argparse.ArgumentParser(description="Runtime dead semantic audit")
    parser.add_argument("--root", default=".")
    parser.add_argument("--report-dir", default=REPORT_DIR_DEFAULT)
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--summary", action="store_true")

    args = parser.parse_args()

    root = Path(args.root).resolve()

    findings: list[Finding] = []
    findings.extend(find_unused_gvl_fields(root))
    findings.extend(find_unused_dut_fields(root))
    findings.extend(find_orphan_dut_types(root))
    findings.extend(find_zombie_patterns(root))

    report = {
        "tool": "runtime_dead_semantic_audit.py",
        "version": 1,
        "started_at_utc": utc_timestamp(),
        "summary": summarize(findings),
        "findings": [asdict(f) for f in findings],
    }

    write_reports(report, root / args.report_dir)

    if args.json:
        print(json.dumps(report, ensure_ascii=False, indent=2))
    else:
        summary = report["summary"]
        print("Runtime dead semantic audit summary")
        print("===================================")
        print(f"UNUSED_GVL_FIELDS: {summary['unused_gvl_fields']}")
        print(f"UNUSED_DUT_FIELDS: {summary['unused_dut_fields']}")
        print(f"ORPHAN_DUT_TYPES: {summary['orphan_dut_types']}")
        print(f"SEMANTIC_ZOMBIE_PATTERNS: {summary['semantic_zombie_patterns']}")
        print(f"TOTAL_FINDINGS: {summary['total_findings']}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
