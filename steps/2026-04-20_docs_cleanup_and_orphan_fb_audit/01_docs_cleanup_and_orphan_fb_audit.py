#!/usr/bin/env python3
from pathlib import Path
import re

repo = Path(".")

# -----------------------------------
# 1. Delete confirmed stale docs
# -----------------------------------
docs_to_delete = [
    Path("docs/PROJECT_ROADMAP.md"),
    Path("docs/PROJECT_STATUS_2026-04-05.md"),
    Path("docs/PROJECT_STATUS_2026-04-06_FULL.md"),
    Path("docs/DEVELOPMENT_WORKFLOW_V2.md"),
]

deleted = []
missing = []

for p in docs_to_delete:
    if p.exists():
        p.unlink()
        deleted.append(str(p))
    else:
        missing.append(str(p))

# -----------------------------------
# 2. Audit root FB_*.st for orphan refs
# -----------------------------------
exclude_dirs = {
    ".git",
    "snapshots",
    "workspace",
    "steps",
    "docs",
    "diagnostics",
    "диагностика",
    "repo_logs",
    "компилятор/logs",
}

def is_excluded(path: Path) -> bool:
    sp = str(path).replace("\\", "/")
    for ex in exclude_dirs:
        if sp == ex or sp.startswith(ex + "/"):
            return True
    return False

root_fb_files = sorted(
    [p for p in repo.glob("FB_*.st") if p.is_file()],
    key=lambda p: p.name.lower()
)

all_scan_files = []
for p in repo.rglob("*"):
    if not p.is_file():
        continue
    rel = p.relative_to(repo)
    if is_excluded(rel):
        continue
    # only scan source-ish files
    if p.suffix.lower() in {".st", ".gvl", ".dut", ".txt", ".md", ".py", ".sh"}:
        all_scan_files.append(rel)

orphan_candidates = []
referenced = []

for fb in root_fb_files:
    token = fb.stem  # e.g. FB_Device_Predictive_Diag
    hits = []

    for rel in all_scan_files:
        if rel == fb:
            continue
        try:
            text = (repo / rel).read_text(encoding="utf-8", errors="ignore")
        except Exception:
            continue
        if token in text:
            hits.append(str(rel))

    if hits:
        referenced.append((fb.name, hits))
    else:
        orphan_candidates.append(fb.name)

# -----------------------------------
# 3. Heuristic shortlist for "good but not integrated"
# -----------------------------------
good_keywords = [
    "Predictive_Diag",
    "IO_Module_Watchdog",
    "State_Snapshot_NVRAM",
    "OpenTherm",
    "TwoFactor_Auth",
    "Valve_Test",
    "Lifetime_Predictor",
]

good_ideas = []
for fb_name in orphan_candidates:
    if any(k in fb_name for k in good_keywords):
        good_ideas.append(fb_name)

report = []
report.append("=== DOC CLEANUP ===")
report.append("Deleted:")
for x in deleted:
    report.append(f"  - {x}")
report.append("Missing:")
for x in missing:
    report.append(f"  - {x}")

report.append("")
report.append("=== ROOT FB ORPHAN CANDIDATES (no textual refs outside own file / excluded dirs) ===")
for x in orphan_candidates:
    report.append(f"  - {x}")

report.append("")
report.append("=== ROOT FB WITH EXTERNAL REFS ===")
for name, hits in referenced:
    report.append(f"  - {name}")
    for h in hits[:10]:
        report.append(f"      * {h}")
    if len(hits) > 10:
        report.append(f"      * ... +{len(hits)-10} more")

report.append("")
report.append("=== GOOD IDEAS / NOT INTEGRATED YET (heuristic shortlist) ===")
for x in good_ideas:
    report.append(f"  - {x}")

Path("диагностика/docs_cleanup_and_orphan_fb_audit.log").write_text(
    "\n".join(report) + "\n",
    encoding="utf-8"
)

# Also create a human-readable markdown summary
md = []
md.append("# Docs cleanup and orphan FB audit")
md.append("")
md.append("## Deleted confirmed stale docs")
for x in deleted:
    md.append(f"- `{x}`")
if not deleted:
    md.append("- none")
md.append("")
md.append("## Orphan root FB candidates")
for x in orphan_candidates:
    md.append(f"- `{x}`")
if not orphan_candidates:
    md.append("- none")
md.append("")
md.append("## Good ideas / not integrated yet")
for x in good_ideas:
    md.append(f"- `{x}`")
if not good_ideas:
    md.append("- none")

Path("диагностика/docs_cleanup_and_orphan_fb_audit.md").write_text(
    "\n".join(md) + "\n",
    encoding="utf-8"
)

print("OK: deleted confirmed stale docs and generated orphan FB audit")
