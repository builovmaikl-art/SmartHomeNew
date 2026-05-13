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

Exit codes:
    0 - no blocking violations found
    1 - blocking violations found

Notes:
    This script is static-pattern based. It is intentionally conservative and
    should be used as a regression guard, not as a full compiler or parser.
"""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
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
}


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
        allowed_paths=(
            "GVL_ALARM.gvl",
            "RUNTIME_REMAINING_RISKS_AND_DEBT.md",
            "RUNTIME_INVARIANTS.md",
            "RUNTIME_VERIFICATION_PLAN.md",
        ),
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


LEASE_RELEASE_TARGETS = (
    "Output_Stale_Detected",
    "Output_Forced_Safe_Decay",
    "Distributed_Snapshot_Quarantine_Active",
    "Distributed_Commit_Quarantine_Active",
    "Recovery_Quarantine_Active",
    "Recovery_Cleanup_Completed",
    "Recovery_Cleanup_Verified",
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


def iter_source_files(root: Path) -> Iterable[Path]:
    for path in root.rglob("*"):
        if not path.is_file():
            continue
        if path.suffix not in SOURCE_SUFFIXES and path.name not in {
            "RUNTIME_REMAINING_RISKS_AND_DEBT.md",
            "RUNTIME_INVARIANTS.md",
            "RUNTIME_VERIFICATION_PLAN.md",
        }:
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


def check_release_before_convergence(root: Path) -> list[Finding]:
    findings: list[Finding] = []
    for path in iter_source_files(root):
        rel = path.relative_to(root)
        if rel.name not in LEASE_REQUIRED_FILES:
            continue
        text = read_text(path)
        lines = text.splitlines()
        for i, line in enumerate(lines):
            if not any(target in line for target in LEASE_RELEASE_TARGETS):
                continue
            if ":= FALSE" not in line and ":= TRUE" not in line:
                continue

            # Look at a small local context. A release line should be in a block that
            # references Convergence_Release_Allowed or Convergence_Lease_OK.
            start = max(0, i - 8)
            end = min(len(lines), i + 4)
            context = "\n".join(lines[start:end])
            if "GVL_CONVERGENCE.Convergence_Release_Allowed" in context:
                continue
            if "GVL_CONVERGENCE.Convergence_Lease_OK" in context:
                continue

            # Invalid-state escalation is allowed to set quarantine/forced-safe TRUE.
            if ":= TRUE" in line and (
                "Quarantine_Active" in line
                or "Forced_Safe" in line
                or "Stale_Detected" in line
                or "Cleanup_Completed" not in line
            ):
                continue

            findings.append(
                Finding(
                    severity="ERROR",
                    check="release_before_convergence",
                    path=rel.as_posix(),
                    line=i + 1,
                    text=line.strip(),
                    detail="Release/completion of protected recovery state must be gated by convergence lease.",
                )
            )
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


def format_findings(findings: list[Finding]) -> str:
    if not findings:
        return "OK: no blocking runtime invariant violations found."

    lines: list[str] = []
    for item in findings:
        location = f"{item.path}:{item.line}" if item.line else item.path
        lines.append(f"[{item.severity}] {item.check} @ {location}")
        lines.append(f"  text: {item.text}")
        lines.append(f"  detail: {item.detail}")
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description="Runtime invariant audit toolkit")
    parser.add_argument("--root", default=".", help="Repository root path")
    parser.add_argument("--strict", action="store_true", help="Treat WARN findings as blocking")
    args = parser.parse_args()

    root = Path(args.root).resolve()
    if not root.exists():
        print(f"ERROR: root does not exist: {root}", file=sys.stderr)
        return 1

    findings: list[Finding] = []
    findings.extend(check_pattern_rules(root, OWNERSHIP_RULES))
    findings.extend(check_pattern_rules(root, STALE_TRUTH_RULES))
    findings.extend(check_pattern_rules(root, PERSISTENCE_RULES))
    findings.extend(check_release_before_convergence(root))
    findings.extend(check_semantic_progress_evidence(root))
    findings.extend(check_convergence_governor(root))

    print(format_findings(findings))

    blocking = [f for f in findings if f.severity == "ERROR" or args.strict]
    return 1 if blocking else 0


if __name__ == "__main__":
    raise SystemExit(main())
