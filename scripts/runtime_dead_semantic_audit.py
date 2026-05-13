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
    Detect-only tool. No automatic deletion or rewriting is performed.

Performance model:
    Single-pass source indexing. Designed for Codespaces/mobile terminal use.

Usage:
    python3 scripts/runtime_dead_semantic_audit.py
    python3 scripts/runtime_dead_semantic_audit.py --summary
    python3 scripts/runtime_dead_semantic_audit.py --json
    python3 scripts/runtime_dead_semantic_audit.py --max-findings 1000

Reports:
    runtime_semantic_reports/latest/
    runtime_semantic_reports/history/
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
from collections import Counter
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

TOKEN_RE = re.compile(r"\b[A-Za-z_][A-Za-z0-9_]*\b")
MEMBER_RE = re.compile(r"\.([A-Za-z_][A-Za-z0-9_]*)\b")
GVL_FIELD_RE = re.compile(r"^\s*(G_[A-Za-z0-9_]+)\s*:")
DUT_FIELD_RE = re.compile(r"^\s*([A-Za-z][A-Za-z0-9_]*)\s*:")
DUT_TYPE_RE = re.compile(r"^\s*TYPE\s+([A-Za-z0-9_]+)", re.IGNORECASE)


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


@dataclass
class SourceIndex:
    token_counts: Counter[str]
    member_counts: Counter[str]
    gvl_fields: list[Declaration]
    dut_fields: list[Declaration]
    dut_types: list[Declaration]
    zombie_findings: list[Finding]
    files_scanned: int


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


def strip_comment(line: str) -> str:
    return line.split("//", 1)[0]


def build_index(root: Path) -> SourceIndex:
    token_counts: Counter[str] = Counter()
    member_counts: Counter[str] = Counter()
    gvl_fields: list[Declaration] = []
    dut_fields: list[Declaration] = []
    dut_types: list[Declaration] = []
    zombie_findings: list[Finding] = []
    files_scanned = 0

    for path in iter_source_files(root):
        files_scanned += 1
        rel = path.relative_to(root).as_posix()
        suffix = path.suffix
        inside_struct = False

        for line_no, raw_line in enumerate(read_text(path).splitlines(), start=1):
            line = strip_comment(raw_line)
            if not line.strip():
                continue

            token_counts.update(TOKEN_RE.findall(line))
            member_counts.update(MEMBER_RE.findall(line))

            if suffix == ".gvl":
                match = GVL_FIELD_RE.search(line)
                if match:
                    gvl_fields.append(Declaration(match.group(1), rel, line_no, "GVL_FIELD"))

            if suffix in {".dut", ".typ"}:
                type_match = DUT_TYPE_RE.search(line)
                if type_match:
                    dut_types.append(Declaration(type_match.group(1), rel, line_no, "DUT_TYPE"))

                stripped = line.strip().upper()
                if stripped == "STRUCT":
                    inside_struct = True
                    continue
                if stripped == "END_STRUCT":
                    inside_struct = False
                    continue

                if inside_struct:
                    field_match = DUT_FIELD_RE.search(line)
                    if field_match:
                        dut_fields.append(Declaration(field_match.group(1), rel, line_no, "DUT_FIELD"))

            for pattern in ZOMBIE_PATTERNS:
                if pattern in line:
                    zombie_findings.append(
                        Finding(
                            category="SEMANTIC_ZOMBIE_PATTERN",
                            severity="INFO",
                            symbol=pattern,
                            path=rel,
                            line=line_no,
                            detail="Potential compatibility/legacy semantic pattern detected.",
                        )
                    )

    return SourceIndex(
        token_counts=token_counts,
        member_counts=member_counts,
        gvl_fields=gvl_fields,
        dut_fields=dut_fields,
        dut_types=dut_types,
        zombie_findings=zombie_findings,
        files_scanned=files_scanned,
    )


def build_findings(index: SourceIndex, max_findings: int) -> tuple[list[Finding], bool]:
    findings: list[Finding] = []
    truncated = False

    def append(item: Finding) -> None:
        nonlocal truncated
        if len(findings) >= max_findings:
            truncated = True
            return
        findings.append(item)

    for decl in index.gvl_fields:
        if index.token_counts.get(decl.symbol, 0) <= 1:
            append(
                Finding(
                    category="UNUSED_GVL_FIELD",
                    severity="WARN",
                    symbol=decl.symbol,
                    path=decl.path,
                    line=decl.line,
                    detail="GVL field appears declared but not referenced.",
                )
            )

    for decl in index.dut_fields:
        if index.member_counts.get(decl.symbol, 0) == 0:
            append(
                Finding(
                    category="UNUSED_DUT_FIELD",
                    severity="WARN",
                    symbol=decl.symbol,
                    path=decl.path,
                    line=decl.line,
                    detail="DUT field appears unused as a member access.",
                )
            )

    for decl in index.dut_types:
        if index.token_counts.get(decl.symbol, 0) <= 1:
            append(
                Finding(
                    category="ORPHAN_DUT_TYPE",
                    severity="WARN",
                    symbol=decl.symbol,
                    path=decl.path,
                    line=decl.line,
                    detail="DUT type appears declared but never instantiated/referenced.",
                )
            )

    for item in index.zombie_findings:
        append(item)

    return findings, truncated


def summarize(findings: list[Finding], index: SourceIndex, truncated: bool) -> dict[str, int | bool]:
    summary: dict[str, int | bool] = {
        "files_scanned": index.files_scanned,
        "gvl_fields_scanned": len(index.gvl_fields),
        "dut_fields_scanned": len(index.dut_fields),
        "dut_types_scanned": len(index.dut_types),
        "unused_gvl_fields": 0,
        "unused_dut_fields": 0,
        "orphan_dut_types": 0,
        "semantic_zombie_patterns": 0,
        "total_findings": len(findings),
        "truncated": truncated,
    }

    for item in findings:
        if item.category == "UNUSED_GVL_FIELD":
            summary["unused_gvl_fields"] = int(summary["unused_gvl_fields"]) + 1
        elif item.category == "UNUSED_DUT_FIELD":
            summary["unused_dut_fields"] = int(summary["unused_dut_fields"]) + 1
        elif item.category == "ORPHAN_DUT_TYPE":
            summary["orphan_dut_types"] = int(summary["orphan_dut_types"]) + 1
        elif item.category == "SEMANTIC_ZOMBIE_PATTERN":
            summary["semantic_zombie_patterns"] = int(summary["semantic_zombie_patterns"]) + 1

    return summary


def summary_text(report: dict) -> str:
    s = report["summary"]
    return "\n".join(
        [
            "Runtime dead semantic audit summary",
            "===================================",
            f"FILES_SCANNED: {s['files_scanned']}",
            f"GVL_FIELDS_SCANNED: {s['gvl_fields_scanned']}",
            f"DUT_FIELDS_SCANNED: {s['dut_fields_scanned']}",
            f"DUT_TYPES_SCANNED: {s['dut_types_scanned']}",
            f"UNUSED_GVL_FIELDS: {s['unused_gvl_fields']}",
            f"UNUSED_DUT_FIELDS: {s['unused_dut_fields']}",
            f"ORPHAN_DUT_TYPES: {s['orphan_dut_types']}",
            f"SEMANTIC_ZOMBIE_PATTERNS: {s['semantic_zombie_patterns']}",
            f"TOTAL_FINDINGS: {s['total_findings']}",
            f"TRUNCATED: {s['truncated']}",
        ]
    ) + "\n"


def write_reports(report: dict, report_dir: Path) -> None:
    latest = report_dir / "latest"
    history = report_dir / "history"
    latest.mkdir(parents=True, exist_ok=True)
    history.mkdir(parents=True, exist_ok=True)

    timestamp = report["started_at_utc"]
    s_text = summary_text(report)
    findings_text = "\n".join(
        f"[{f['category']}] {f['symbol']} @ {f['path']}:{f['line']} - {f['detail']}"
        for f in report["findings"]
    ) + "\n"
    json_text = json.dumps(report, ensure_ascii=False, indent=2) + "\n"

    latest_summary = latest / "runtime_dead_semantic_summary.txt"
    latest_log = latest / "runtime_dead_semantic_latest.log"
    latest_json = latest / "runtime_dead_semantic_latest.json"

    latest_summary.write_text(s_text, encoding="utf-8")
    latest_log.write_text(s_text + "\n" + findings_text, encoding="utf-8")
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
    parser.add_argument("--max-findings", type=int, default=5000)
    args = parser.parse_args()

    root = Path(args.root).resolve()
    index = build_index(root)
    findings, truncated = build_findings(index, max_findings=args.max_findings)

    report = {
        "tool": "runtime_dead_semantic_audit.py",
        "version": 2,
        "started_at_utc": utc_timestamp(),
        "summary": summarize(findings, index, truncated),
        "findings": [asdict(f) for f in findings],
    }

    write_reports(report, root / args.report_dir)

    if args.json:
        print(json.dumps(report, ensure_ascii=False, indent=2))
    else:
        print(summary_text(report), end="")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
