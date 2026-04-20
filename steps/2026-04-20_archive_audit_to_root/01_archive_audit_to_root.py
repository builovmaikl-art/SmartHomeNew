#!/usr/bin/env python3
from pathlib import Path
import re

repo = Path(".")

archive_root = repo / "archive"
output_md = repo / "ARCHIVE_AUDIT_2026-04-20.md"
output_log = repo / "диагностика" / "archive_audit_to_root.log"

if not archive_root.exists():
    raise SystemExit("archive/ directory not found")

st_files = sorted([p for p in archive_root.rglob("*.st") if p.is_file()])

def classify_by_name(name: str) -> str:
    n = name.lower()
    if "controller" in n or "valve" in n or "pump" in n or "ventilation" in n or "lighting" in n:
        return "unintegrated_controller"
    if "snapshot" in n or "predictive" in n or "presence" in n or "access" in n or "distribution" in n:
        return "good_idea_not_integrated"
    return "needs_manual_review"

def read_head(path: Path, max_lines: int = 40) -> str:
    try:
        text = path.read_text(encoding="utf-8", errors="ignore")
    except Exception:
        return ""
    lines = text.splitlines()
    return "\n".join(lines[:max_lines])

items = []
for p in st_files:
    head = read_head(p)
    rel = str(p.relative_to(repo)).replace("\\", "/")
    name = p.name
    cls = classify_by_name(name)

    summary = "No quick summary"
    if "FUNCTION_BLOCK" in head:
        m = re.search(r"FUNCTION_BLOCK\s+([A-Za-z0-9_]+)", head)
        if m:
            summary = f"Function block `{m.group(1)}` archived after cleanup"

    if "VI_" in head or "VO_" in head or "VIO_" in head:
        summary += "; has explicit FB-style interface"

    items.append({
        "path": rel,
        "name": name,
        "class": cls,
        "summary": summary,
    })

groups = {
    "unintegrated_controller": [],
    "good_idea_not_integrated": [],
    "needs_manual_review": [],
}

for item in items:
    groups[item["class"]].append(item)

md = []
md.append("# ARCHIVE AUDIT — 2026-04-20")
md.append("")
md.append("Purpose: preserve a root-level working memory of what was moved into `archive/` during cleanup, so the repository does not lose track of potentially valuable blocks.")
md.append("")
md.append("This file is intentionally stored in the repository root to stay visible during future refactor sessions.")
md.append("")
md.append("## Summary")
md.append(f"- Total archived `.st` blocks reviewed: **{len(items)}**")
md.append(f"- Unintegrated controllers: **{len(groups['unintegrated_controller'])}**")
md.append(f"- Good ideas not integrated: **{len(groups['good_idea_not_integrated'])}**")
md.append(f"- Needs manual review: **{len(groups['needs_manual_review'])}**")
md.append("")

md.append("## 1. Unintegrated controllers")
if groups["unintegrated_controller"]:
    for item in groups["unintegrated_controller"]:
        md.append(f"- `{item['path']}` — {item['summary']}")
else:
    md.append("- none")
md.append("")

md.append("## 2. Good ideas / not integrated yet")
if groups["good_idea_not_integrated"]:
    for item in groups["good_idea_not_integrated"]:
        md.append(f"- `{item['path']}` — {item['summary']}")
else:
    md.append("- none")
md.append("")

md.append("## 3. Needs manual review")
if groups["needs_manual_review"]:
    for item in groups["needs_manual_review"]:
        md.append(f"- `{item['path']}` — {item['summary']}")
else:
    md.append("- none")
md.append("")

md.append("## 4. Recommended interpretation")
md.append("- `unintegrated_controller`: do not restore directly into the root; reintroduce only through manager/policy orchestration.")
md.append("- `good_idea_not_integrated`: preserve as a feature shortlist for future controlled integration.")
md.append("- `needs_manual_review`: inspect individually before any delete/restore decision.")
md.append("")

md.append("## 5. Current recommendation")
md.append("- Keep `archive/` as a quarantine zone, not as live code.")
md.append("- Use this file as the single visible entry point for archived design assets.")
md.append("- Any future resurrection must happen through a deterministic step with compile verification.")
md.append("")

output_md.write_text("\n".join(md) + "\n", encoding="utf-8")

log = []
log.append("=== ARCHIVE AUDIT TO ROOT ===")
log.append(f"archive dir: {archive_root}")
log.append(f"total archived .st files: {len(items)}")
log.append(f"unintegrated controllers: {len(groups['unintegrated_controller'])}")
log.append(f"good ideas not integrated: {len(groups['good_idea_not_integrated'])}")
log.append(f"needs manual review: {len(groups['needs_manual_review'])}")
log.append(f"root report: {output_md}")

output_log.write_text("\n".join(log) + "\n", encoding="utf-8")

print("OK: archive audit saved to repository root")
