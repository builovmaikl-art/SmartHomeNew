#!/usr/bin/env python3
"""
Runtime invariant audit toolkit.

Purpose:
    Detect regression of deterministic runtime governance invariants:
    - hidden writers;
    - duplicate ownership;
    - release-before-convergence;
    - persistent authority resurrection;
    - stale safety truth usage;
    - semantic progress self-validation regression.

Usage:
    python3 scripts/runtime_invariant_audit.py
    python3 scripts/runtime_invariant_audit.py --root /path/to/repo
    python3 scripts/runtime_invariant_audit.py --strict
    python3 scripts/runtime_invariant_audit.py --report-dir runtime_verification_reports

Exit codes:
    0 - no blocking violations found
    1 - blocking violations found

Reports:
    By default the script writes:
      runtime_verification_reports/latest/runtime_verification_latest.log
      runtime_verification_reports/latest/runtime_verification_latest.json
      runtime_verification_reports/latest/runtime_verification_summary.txt
      runtime_verification_reports/history/<timestamp>_runtime_verification.*

Notes:
    This script is static-pattern based. It is intentionally conservative and
    should be used as a regression guard, not as a full compiler or parser.
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import sys
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable, Pattern


SOURCE_SUFFIXES = {".st", ".gvl"}
EXCLUDED_PARTS = {
    ".git",
    "snapshots",
    "archive",
    "archives",
    "docs",
    "reports",
    "logs",
    "runtime_verification_reports",
}

REPORT_DIR_DEFAULT = "runtime_verification_reports"


@dataclass(frozen=True)
class Finding:
    severity: str
    check: str
    path: str
    line: int
    text: str
    detail: str


@dataclass(frozen=True)
class PatternRule:
    name: str
    severity: str
    pattern: Pattern[str]
    allowed_paths: tuple[str, ...]
    detail: str


OWNERSHIP_RULES: tuple[PatternRule, ...] = (
    PatternRule(
        name="system_mode_writer",
        severity="ERROR",
        pattern=re.compile(r"\bGVL_STATE\.G_System_Mode\s*:=", re.IGNORECASE),
        allowed_paths=("FB_System_Health_Orchestrator.st",),
        detail="G_System_Mode must be written only through FB_System_Health_Orchestrator / FB_State_Manager path.",
    ),
    PatternRule(
        name="safety_latch_writer",
        severity="ERROR",
        pattern=re.compile(r"\bGVL_STATE\.G_Safety_(Gas|Leak|Smoke)_Latched\s*:=", re.IGNORECASE),
        allowed_paths=("FB_Safety_Manager.st",),
        detail="Safety latches must be owned by FB_Safety_Manager only.",
    ),
    PatternRule(
        name="diagnostics_sensor_fault_aggregate_writer",
        severity="ERROR",
        pattern=re.compile(r"\bGVL_STATUS\.G_Diagnostics\.Sensor_Fault\s*:=", re.IGNORECASE),
        allowed_paths=("FB_System_Health_Orchestrator.st", "PRG_IO_Read.st"),
        detail="Sensor_Fault aggregate must remain controlled by canonical health/diagnostics ownership. Review any writer carefully.",
    ),
    PatternRule(
        name="diagnostics_io_offline_aggregate_writer",
        severity="ERROR",
        pattern=re.compile(r"\bGVL_STATUS\.G_Diagnostics\.IO_Offline\s*:=", re.IGNORECASE),
        allowed_paths=("FB_System_Health_Orchestrator.st",),
        detail="IO_Offline aggregate must be owned by FB_System_Health_Orchestrator.",
    ),
    PatternRule(
        name="diagnostics_subsystem_degraded_aggregate_writer",
        severity="ERROR",
        pattern=re.compile(r"\bGVL_STATUS\.G_Diagnostics\.Subsystem_Degraded\s*:=", re.IGNORECASE),
        allowed_paths=("FB_System_Health_Orchestrator.st", "PRG_IO_Read.st", "PRG_Policy.st"),
        detail="Subsystem_Degraded aggregate writer must be reviewed; avoid duplicate aggregate ownership.",
    ),
    PatternRule(
        name="opentherm_online_writer",
        severity="ERROR",
        pattern=re.compile(r"\bGVL_STATE\.G_Boiler_OT_Online\s*\[.*?\]\s*:=", re.IGNORECASE),
        allowed_paths=("PRG_OpenTherm_Adapter_Status.st",),
        detail="Canonical OpenTherm online state must not be reset from raw IO layers.",
    ),
    PatternRule(
        name="boiler_flame_writer",
        severity="ERROR",
        pattern=re.compile(r"\bGVL_STATE\.G_Boiler_Flame\s*\[.*?\]\s*:=", re.IGNORECASE),
        allowed_paths=("PRG_OpenTherm_Adapter_Status.st",),
        detail="Boiler flame status must be owned by PRG_OpenTherm_Adapter_Status.",
    ),
    PatternRule(
        name="boiler_error_writer",
        severity="ERROR",
        pattern=re.compile(r"\bGVL_STATE\.G_Boiler_Error\s*\[.*?\]\s*:=", re.IGNORECASE),
        allowed_paths=("PRG_OpenTherm_Adapter_Status.st",),
        detail="Boiler error status must be owned by PRG_OpenTherm_Adapter_Status.",
    ),
)


STALE_TRUTH_RULES: tuple[PatternRule, ...] = (
    PatternRule(
        name="stale_alarm_active_truth_usage",
        severity="WARN",
        pattern=re.compile(r"\bGVL_ALARM\.G_.*_Alarm_Active\b", re.IGNORECASE),
        allowed_paths=("GVL_ALARM.gvl",),
        detail="Alarm active projections must not be used as authoritative safety truth; prefer GVL_HEALTH_BRIDGE.",
    ),
    PatternRule(
        name="stale_state_safety_alarm_truth_usage",
        severity="WARN",
        pattern=re.compile(r"\bGVL_STATE\.G_Safety_.*_Alarm\b", re.IGNORECASE),
        allowed_paths=("GVL_STATE.gvl",),
        detail="GVL_STATE safety alarm fields must not replace GVL_HEALTH_BRIDGE truth for latch/alarm authority.",
    ),
)


PERSISTENCE_RULES: tuple[PatternRule, ...] = (
    PatternRule(
        name="persistent_system_mode_restore",
        severity="ERROR",
        pattern=re.compile(r"G_System_Mode\s*:=\s*GVL_PERSISTENT|GVL_PERSISTENT\..*System_Mode", re.IGNORECASE),
        allowed_paths=("FB_System_Persist_Manager.st", "GVL_PERSISTENT.gvl"),
        detail="Persistent storage must not restore authoritative system mode into runtime state.",
    ),
    PatternRule(
        name="persistent_safety_latch_restore",
        severity="ERROR",
        pattern=re.compile(r"G_Safety_.*_Latched\s*:=\s*GVL_PERSISTENT|GVL_PERSISTENT\..*Safety_.*Latched", re.IGNORECASE),
        allowed_paths=("FB_System_Persist_Manager.st", "GVL_PERSISTENT.gvl"),
        detail="Persistent storage must not restore authoritative safety latches into runtime state.",
    ),
)


# TRUE values are usually release/completion. FALSE values are often safe invalidation
# and should not be reported unless the context explicitly looks like a release path.
LEASE_RELEASE_TRUE_TARGETS = (
    "Recovery_Cleanup_Completed",
    "Recovery_Cleanup_Verified",
)

LEASE_RELEASE_FALSE_TARGETS = (
    "Output_Stale_Detected",
    "Output_Forced_Safe_Decay",
    "Distributed_Snapshot_Quarantine_Active",
    "Distributed_Commit_Quarantine_Active",
    "Recovery_Quarantine_Active",
)

LEASE_REQUIRED_FILES = {
    "PRG_Output_Freshness_Governor.st",
    "PRG_Distributed_Snapshot_Governor.st",
    "PRG_Distributed_Commit_Governor.st",
    "PRG_Recovery_Cleanup_Governor.st",
    "FB_State_Manager.st",
}


SEMANTIC_REQUIRED_EVIDENCE = (
    "GVL_RUNTIME_EPOCH.Runtime_Epoch",
    "GVL_RUNTIME_SNAPSHOT.Snapshot_Epoch",
    "GVL_DISTRIBUTED_COMMIT.Distributed_Commit_Epoch",
    "GVL_OUTPUT_EPOCH.Output_Publication_Epoch",
)


def utc_timestamp() -> str:
    return datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")


def iter_source_files(root: Path) -> Iterable[Path]:
    for path in root.rglob("*"):
        if not path.is_file():
            continue
        if path.suffix not in SOURCE_SUFFIXES:
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


def is_allowed(path: Path, allowed_paths: tuple[str, ...]) -> bool:
    normalized = path.as_posix()
    return any(normalized.endswith(allowed) for allowed in allowed_paths)


def check_pattern_rules(root: Path, rules: Iterable[PatternRule]) -> list[Finding]:
    findings: list[Finding] = []
    for path in iter_source_files(root):
        rel = path.relative_to(root)
        text = read_text(path)
        for line_no, line in enumerate(text.splitlines(), start=1):
            for rule in rules:
                if not rule.pattern.search(line):
                    continue
                if is_allowed(rel, rule.allowed_paths):
                    continue
                findings.append(
                    Finding(
                        severity=rule.severity,
                        check=rule.name,
                        path=rel.as_posix(),
                        line=line_no,
                        text=line.strip(),
                        detail=rule.detail,
                    )
                )
    return findings


def context_has_lease(context: str) -> bool:
    return (
        "GVL_CONVERGENCE.Convergence_Release_Allowed" in context
        or "GVL_CONVERGENCE.Convergence_Lease_OK" in context
    )


def context_looks_like_release(context: str) -> bool:
    lowered = context.lower()
    return (
        "l_recovery_valid" in lowered
        or "l_output_valid" in lowered
        or "l_commit_valid" in lowered
        or "l_distributed_snapshot_valid" in lowered
        or "if l_" in lowered and "valid" in lowered
    )


def check_release_before_convergence(root: Path) -> list[Finding]:
    findings: list[Finding] = []
    for path in iter_source_files(root):
        rel = path.relative_to(root)
        if rel.name not in LEASE_REQUIRED_FILES:
            continue
        text = read_text(path)
        lines = text.splitlines()
        for i, line in enumerate(lines):
            target_true = any(target in line for target in LEASE_RELEASE_TRUE_TARGETS)
            target_false = any(target in line for target in LEASE_RELEASE_FALSE_TARGETS)
            if not (target_true or target_false):
                continue

            start = max(0, i - 10)
            end = min(len(lines), i + 5)
            context = "\n".join(lines[start:end])
            if context_has_lease(context):
                continue

            stripped = line.strip()

            # Completion TRUE without lease is unsafe release.
            if target_true and ":= TRUE" in stripped:
                findings.append(
                    Finding(
                        severity="ERROR",
                        check="release_before_convergence",
                        path=rel.as_posix(),
                        line=i + 1,
                        text=stripped,
                        detail="Completion/release TRUE of protected recovery state must be gated by convergence lease.",
                    )
                )
                continue

            # Quarantine/stale/forced-safe FALSE can be release; flag only if the local context looks like valid/recovery path.
            if target_false and ":= FALSE" in stripped and context_looks_like_release(context):
                findings.append(
                    Finding(
                        severity="ERROR",
                        check="release_before_convergence",
                        path=rel.as_posix(),
                        line=i + 1,
                        text=stripped,
                        detail="Release FALSE of protected recovery/quarantine state must be gated by convergence lease.",
                    )
                )
                continue

            # FALSE on completion/verified is invalidation and should not be treated as release.
            # TRUE on quarantine/stale/forced-safe is escalation and is allowed.
    return findings


def check_semantic_progress_evidence(root: Path) -> list[Finding]:
    findings: list[Finding] = []
    target = root / "PRG_Semantic_Progress_Governor.st"
    if not target.exists():
        return [
            Finding(
                severity="ERROR",
                check="semantic_progress_file_missing",
                path="PRG_Semantic_Progress_Governor.st",
                line=0,
                text="missing",
                detail="Semantic progress governor must exist and validate runtime phase evidence.",
            )
        ]
    text = read_text(target)
    for evidence in SEMANTIC_REQUIRED_EVIDENCE:
        if evidence not in text:
            findings.append(
                Finding(
                    severity="ERROR",
                    check="semantic_phase_evidence_missing",
                    path="PRG_Semantic_Progress_Governor.st",
                    line=0,
                    text=evidence,
                    detail="Semantic progress must validate real runtime phase evidence, not self-counter only.",
                )
            )
    return findings


def check_convergence_governor(root: Path) -> list[Finding]:
    findings: list[Finding] = []
    target = root / "PRG_Convergence_Governor.st"
    if not target.exists():
        return [
            Finding(
                severity="ERROR",
                check="convergence_governor_missing",
                path="PRG_Convergence_Governor.st",
                line=0,
                text="missing",
                detail="Convergence governor must exist.",
            )
        ]
    text = read_text(target)
    required = (
        "Recovery_Stable_Cycle_Count",
        "Recovery_Stable_Time_MS",
        "Convergence_Lease_OK",
        "Convergence_Release_Allowed",
    )
    for token in required:
        if token not in text:
            findings.append(
                Finding(
                    severity="ERROR",
                    check="convergence_token_missing",
                    path="PRG_Convergence_Governor.st",
                    line=0,
                    text=token,
                    detail="Convergence governor must maintain stable-cycle/time lease semantics.",
                )
            )

    forbidden = (
        "Distributed_Snapshot_Quarantine_Active",
        "Distributed_Commit_Quarantine_Active",
        "Semantic_Progress_Quarantine_Active",
        "Output_Forced_Safe_Decay",
        "Output_Stale_Detected",
    )
    for token in forbidden:
        if token in text:
            findings.append(
                Finding(
                    severity="ERROR",
                    check="convergence_circular_dependency",
                    path="PRG_Convergence_Governor.st",
                    line=0,
                    text=token,
                    detail="Convergence lease must not depend on flags that are released by convergence lease.",
                )
            )
    return findings


def summarize(findings: list[Finding], strict: bool) -> dict[str, object]:
    errors = sum(1 for f in findings if f.severity == "ERROR")
    warnings = sum(1 for f in findings if f.severity == "WARN")
    blocking = errors + (warnings if strict else 0)
    return {
        "status": "FAILED" if blocking else "PASSED",
        "errors": errors,
        "warnings": warnings,
        "total_findings": len(findings),
        "strict": strict,
        "blocking_findings": blocking,
    }


def format_summary(summary: dict[str, object]) -> str:
    return "\n".join(
        [
            "Runtime invariant audit summary",
            "================================",
            f"STATUS: {summary['status']}",
            f"ERRORS: {summary['errors']}",
            f"WARNINGS: {summary['warnings']}",
            f"TOTAL FINDINGS: {summary['total_findings']}",
            f"STRICT MODE: {summary['strict']}",
            f"BLOCKING FINDINGS: {summary['blocking_findings']}",
        ]
    )


def format_findings(findings: list[Finding]) -> str:
    if not findings:
        return "OK: no runtime invariant findings."

    lines: list[str] = []
    for item in findings:
        location = f"{item.path}:{item.line}" if item.line else item.path
        lines.append(f"[{item.severity}] {item.check} @ {location}")
        lines.append(f"  text: {item.text}")
        lines.append(f"  detail: {item.detail}")
    return "\n".join(lines)


def build_report(root: Path, findings: list[Finding], strict: bool, started_at: str) -> dict[str, object]:
    summary = summarize(findings, strict)
    return {
        "tool": "runtime_invariant_audit.py",
        "version": 2,
        "started_at_utc": started_at,
        "root": str(root),
        "summary": summary,
        "findings": [asdict(f) for f in findings],
    }


def write_reports(report: dict[str, object], report_dir: Path) -> dict[str, str]:
    latest = report_dir / "latest"
    history = report_dir / "history"
    latest.mkdir(parents=True, exist_ok=True)
    history.mkdir(parents=True, exist_ok=True)

    started = str(report["started_at_utc"])
    stem = f"{started}_runtime_verification"

    findings = [Finding(**item) for item in report["findings"]]  # type: ignore[arg-type]
    summary_text = format_summary(report["summary"])  # type: ignore[arg-type]
    log_text = summary_text + "\n\n" + format_findings(findings) + "\n"
    json_text = json.dumps(report, ensure_ascii=False, indent=2) + "\n"

    latest_log = latest / "runtime_verification_latest.log"
    latest_json = latest / "runtime_verification_latest.json"
    latest_summary = latest / "runtime_verification_summary.txt"

    latest_log.write_text(log_text, encoding="utf-8")
    latest_json.write_text(json_text, encoding="utf-8")
    latest_summary.write_text(summary_text + "\n", encoding="utf-8")

    history_log = history / f"{stem}.log"
    history_json = history / f"{stem}.json"
    history_summary = history / f"{stem}_summary.txt"
    shutil.copyfile(latest_log, history_log)
    shutil.copyfile(latest_json, history_json)
    shutil.copyfile(latest_summary, history_summary)

    return {
        "latest_log": latest_log.as_posix(),
        "latest_json": latest_json.as_posix(),
        "latest_summary": latest_summary.as_posix(),
        "history_log": history_log.as_posix(),
        "history_json": history_json.as_posix(),
        "history_summary": history_summary.as_posix(),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Runtime invariant audit toolkit")
    parser.add_argument("--root", default=".", help="Repository root path")
    parser.add_argument("--strict", action="store_true", help="Treat WARN findings as blocking")
    parser.add_argument("--report-dir", default=REPORT_DIR_DEFAULT, help="Directory for persistent verification reports")
    parser.add_argument("--no-report", action="store_true", help="Do not write persistent report files")
    parser.add_argument("--json", action="store_true", help="Print JSON report to stdout")
    parser.add_argument("--summary", action="store_true", help="Print summary only to stdout")
    args = parser.parse_args()

    root = Path(args.root).resolve()
    if not root.exists():
        print(f"ERROR: root does not exist: {root}", file=sys.stderr)
        return 1

    started_at = utc_timestamp()
    findings: list[Finding] = []
    findings.extend(check_pattern_rules(root, OWNERSHIP_RULES))
    findings.extend(check_pattern_rules(root, STALE_TRUTH_RULES))
    findings.extend(check_pattern_rules(root, PERSISTENCE_RULES))
    findings.extend(check_release_before_convergence(root))
    findings.extend(check_semantic_progress_evidence(root))
    findings.extend(check_convergence_governor(root))

    report = build_report(root, findings, args.strict, started_at)
    summary = report["summary"]

    if not args.no_report:
        paths = write_reports(report, root / args.report_dir)
        report["report_paths"] = paths

    if args.json:
        print(json.dumps(report, ensure_ascii=False, indent=2))
    elif args.summary:
        print(format_summary(summary))  # type: ignore[arg-type]
    else:
        print(format_summary(summary))  # type: ignore[arg-type]
        print()
        print(format_findings(findings))
        if not args.no_report:
            paths = report.get("report_paths", {})
            print()
            print("Reports written:")
            for key, value in paths.items():
                print(f"  {key}: {value}")

    blocking = int(summary["blocking_findings"])  # type: ignore[index]
    return 1 if blocking else 0


if __name__ == "__main__":
    raise SystemExit(main())
