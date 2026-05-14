#!/usr/bin/env python3
"""
Focused runtime zombie semantic classifier.

Purpose:
    Classify semantic zombie patterns detected by runtime_dead_semantic_audit.py
    into live contracts, compatibility surfaces and real cleanup candidates.

This tool is intentionally conservative. It does not delete or rewrite code.
"""

from __future__ import annotations

import json
import re
import shutil
from collections import Counter, defaultdict
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable

INCLUDE_SUFFIXES = {".st", ".gvl", ".dut", ".typ"}
EXCLUDED_PARTS = {
    ".git",
    "archive",
    "archives",
    "backup",
    "backups",
    "generated",
    "docs",
    "logs",
    "reports",
    "snapshots",
    "runtime_verification_reports",
    "runtime_semantic_reports",
}

REPORT_DIR_DEFAULT = "runtime_semantic_reports"
PATTERNS = ("_Alarm_Active", "Legacy_", "Shadow_", "Compatibility_")

LIVE_SAFETY_GATEWAY_FILES = {
    "PRG_Safety.st",
    "GVL_INTENT_SAFETY.gvl",
    "FB_System_Gateway_Intent.st",
    "FB_Gateway_Interface.st",
    "FB_Security_System_Manager.st",
    "PRG_Security.st",
    "PRG_Safety_Shutdown.st",
}

LIVE_ALARM_SYMBOL_RE = re.compile(
    r"\b(?:I_|VI_|VO_|L_|G_)?(?:Fire|Gas|Leak|Flood|Smoke|CO|Security|Siren)_[A-Za-z0-9_]*Alarm_Active\b"
    r"|\b(?:VI_|VO_)?Alarm_Active\b"
)

ASSIGNMENT_RE = re.compile(r"(?P<left>[A-Za-z0-9_\.]+)\s*:=\s*(?P<right>.*?);")


@dataclass(frozen=True)
class ZombieFinding:
    pattern: str
    symbol: str
    path: str
    line: int
    raw: str
    classification: str
    role: str
    detail: str


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


def extract_symbol(line: str, pattern: str) -> str:
    matches = re.findall(r"\b[A-Za-z_][A-Za-z0-9_]*" + re.escape(pattern) + r"[A-Za-z0-9_]*\b", line)
    if matches:
        return matches[0]
    if pattern == "_Alarm_Active":
        generic = LIVE_ALARM_SYMBOL_RE.findall(line)
        if generic:
            return generic[0]
    return pattern


def classify(path: str, line: str, pattern: str, symbol: str) -> tuple[str, str, str]:
    code = strip_comment(line).strip()

    if pattern == "_Alarm_Active":
        if path in LIVE_SAFETY_GATEWAY_FILES and LIVE_ALARM_SYMBOL_RE.search(code):
            role = "ALARM_CONTRACT"
            if path == "PRG_Safety.st" or path == "GVL_INTENT_SAFETY.gvl":
                role = "AUTHORITATIVE_SAFETY_INTENT"
            elif path == "FB_System_Gateway_Intent.st":
                role = "SAFETY_TO_GATEWAY_BRIDGE"
            elif path == "FB_Gateway_Interface.st":
                role = "EXTERNAL_TELEMETRY_ALARM_CONTRACT"
            elif path == "FB_Security_System_Manager.st":
                role = "SECURITY_RUNTIME_ALARM_OUTPUT"
            return (
                "LIVE_COMPATIBILITY_SEMANTICS",
                role,
                "Alarm-active naming is part of a live safety/security/gateway contract; do not delete solely as zombie pattern.",
            )

        if "Alarm_Active" in code:
            return (
                "REVIEW_ALARM_SEMANTICS",
                "UNKNOWN_ALARM_CONTRACT",
                "Alarm-active naming found outside known live contract files; review before cleanup.",
            )

    if pattern in {"Legacy_", "Shadow_", "Compatibility_"}:
        assignment = ASSIGNMENT_RE.search(code)
        if assignment:
            return (
                "COMPATIBILITY_SURFACE_REVIEW",
                "COMPATIBILITY_ASSIGNMENT",
                "Compatibility-style assignment found; classify producer/consumer before removal.",
            )
        return (
            "COMPATIBILITY_SURFACE_REVIEW",
            "COMPATIBILITY_REFERENCE",
            "Compatibility-style reference found; review if still needed by HMI/gateway/snapshots.",
        )

    return (
        "UNCLASSIFIED_ZOMBIE_PATTERN",
        "UNKNOWN",
        "Pattern detected but no conservative classification rule matched.",
    )


def build_report(root: Path) -> dict:
    findings: list[ZombieFinding] = []
    files_scanned = 0

    for path in iter_source_files(root):
        files_scanned += 1
        rel = path.relative_to(root).as_posix()
        for line_no, raw in enumerate(read_text(path).splitlines(), start=1):
            code = strip_comment(raw)
            if not code.strip():
                continue
            for pattern in PATTERNS:
                if pattern not in code:
                    continue
                symbol = extract_symbol(code, pattern)
                classification, role, detail = classify(rel, code, pattern, symbol)
                findings.append(
                    ZombieFinding(
                        pattern=pattern,
                        symbol=symbol,
                        path=rel,
                        line=line_no,
                        raw=code.strip(),
                        classification=classification,
                        role=role,
                        detail=detail,
                    )
                )

    by_class = Counter(item.classification for item in findings)
    by_pattern = Counter(item.pattern for item in findings)
    by_role = Counter(item.role for item in findings)
    by_file = Counter(item.path for item in findings)

    return {
        "tool": "runtime_zombie_semantic_audit.py",
        "version": 1,
        "started_at_utc": utc_timestamp(),
        "summary": {
            "files_scanned": files_scanned,
            "total_zombie_pattern_hits": len(findings),
            "by_classification": dict(sorted(by_class.items())),
            "by_pattern": dict(sorted(by_pattern.items())),
            "by_role": dict(sorted(by_role.items())),
            "by_file": dict(sorted(by_file.items())),
        },
        "findings": [asdict(item) for item in findings],
    }


def summary_text(report: dict) -> str:
    s = report["summary"]
    lines = [
        "Runtime zombie semantic audit summary",
        "=====================================",
        f"FILES_SCANNED: {s['files_scanned']}",
        f"TOTAL_ZOMBIE_PATTERN_HITS: {s['total_zombie_pattern_hits']}",
        "",
        "BY_CLASSIFICATION:",
    ]
    for key, value in s["by_classification"].items():
        lines.append(f"  {key}: {value}")
    lines.append("")
    lines.append("BY_PATTERN:")
    for key, value in s["by_pattern"].items():
        lines.append(f"  {key}: {value}")
    lines.append("")
    lines.append("BY_ROLE:")
    for key, value in s["by_role"].items():
        lines.append(f"  {key}: {value}")
    lines.append("")
    lines.append("BY_FILE:")
    for key, value in s["by_file"].items():
        lines.append(f"  {key}: {value}")
    return "\n".join(lines) + "\n"


def write_reports(report: dict, report_dir: Path) -> None:
    latest = report_dir / "latest"
    history = report_dir / "history"
    latest.mkdir(parents=True, exist_ok=True)
    history.mkdir(parents=True, exist_ok=True)

    timestamp = report["started_at_utc"]
    text = summary_text(report)
    log = text + "\n" + "\n".join(
        f"[{f['classification']}] {f['pattern']} {f['symbol']} @ {f['path']}:{f['line']} - {f['role']} - {f['detail']} :: {f['raw']}"
        for f in report["findings"]
    ) + "\n"
    json_text = json.dumps(report, ensure_ascii=False, indent=2) + "\n"

    (latest / "runtime_zombie_semantic_summary.txt").write_text(text, encoding="utf-8")
    (latest / "runtime_zombie_semantic_latest.log").write_text(log, encoding="utf-8")
    (latest / "runtime_zombie_semantic_latest.json").write_text(json_text, encoding="utf-8")

    shutil.copyfile(latest / "runtime_zombie_semantic_summary.txt", history / f"{timestamp}_runtime_zombie_semantic_summary.txt")
    shutil.copyfile(latest / "runtime_zombie_semantic_latest.log", history / f"{timestamp}_runtime_zombie_semantic.log")
    shutil.copyfile(latest / "runtime_zombie_semantic_latest.json", history / f"{timestamp}_runtime_zombie_semantic.json")


def main() -> int:
    root = Path(".").resolve()
    report = build_report(root)
    write_reports(report, root / REPORT_DIR_DEFAULT)
    print(summary_text(report), end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
