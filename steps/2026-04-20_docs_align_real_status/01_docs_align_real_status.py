#!/usr/bin/env python3
from pathlib import Path

refactor_path = Path("docs/REFACTOR_PLAN_ARCH_ALIGNMENT.md")
audit_path = Path("docs/FB_INVENTORY_AUDIT.md")

refactor = refactor_path.read_text(encoding="utf-8")
audit = audit_path.read_text(encoding="utf-8")

# -----------------------------
# docs/REFACTOR_PLAN_ARCH_ALIGNMENT.md
# -----------------------------
refactor = refactor.replace(
    "Status: Draft plan for controlled repository refactor",
    "Status: Active working plan with partial implementation checkpoints reflected"
)

old_issue = "- `FB_System_Health` is not present as a visible dedicated block"
new_issue = "- `FB_System_Health` now exists and is integrated, but broader subsystem role separation remains incomplete"
if old_issue not in refactor:
    raise SystemExit("Expected systemic issue line about FB_System_Health not found")
refactor = refactor.replace(old_issue, new_issue, 1)

obj_anchor = "This plan is intended as project memory and execution roadmap.\n"
progress_block = """

### Current verified implementation checkpoints

The following items are already reflected in the current repository code and must not be treated as TODO-only aspirations:

- `FB_System_Health` exists and is integrated in `PRG_System`
- persistence architecture is aligned as `GVL_PERSISTENT` primary recovery + NVRAM secondary mirror
- `FB_Persist_Builder` is introduced for build/mirror responsibilities
- `FB_Persist_Pipeline` is introduced for serialize/throttle/write responsibilities
- `FB_NVRAM_Manager` is normalized as explicit write-only executor (`READ` is not implemented by design)

"""
if progress_block.strip() not in refactor:
    if obj_anchor not in refactor:
        raise SystemExit("Objective anchor not found in refactor plan")
    refactor = refactor.replace(obj_anchor, obj_anchor + progress_block, 1)

stage7_anchor = "## Stage 7 — Clean state ownership and persistence boundaries\n"
stage7_note = """## Stage 7 — Clean state ownership and persistence boundaries
Purpose: Remove duplicated state authority.

Implementation note (current status):
- persistence sub-scope is partially completed
- `GVL_PERSISTENT` is the primary recovery source
- `FB_Persist_Builder` performs persist struct build + mirror
- `FB_Persist_Pipeline` performs serialize + controlled NVRAM write
- `FB_NVRAM_Manager` is low-level write-only and no longer carries duplicate rate-limit policy

"""
if stage7_anchor not in refactor:
    raise SystemExit("Stage 7 anchor not found in refactor plan")
refactor = refactor.replace(stage7_anchor, stage7_note, 1)

queue_anchor = "## 7. First execution queue (recommended order)\n"
queue_prefix = """## 7. First execution queue (recommended order)

Checkpoint already completed before the next queue item selection:
- persistence architecture alignment completed to stable code-compiling checkpoint
- documentation alignment is now being updated to match that reality

"""
if queue_anchor not in refactor:
    raise SystemExit("Execution queue anchor not found in refactor plan")
refactor = refactor.replace(queue_anchor, queue_prefix, 1)

refactor_path.write_text(refactor, encoding="utf-8")

# -----------------------------
# docs/FB_INVENTORY_AUDIT.md
# -----------------------------
old_nvram_row = "| FB_NVRAM_Manager | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |"
new_nvram_row = "| FB_NVRAM_Manager | REVIEWED | Persistence / Diagnostics / History | Low-level NVRAM/RETAIN writer with validation and explicit no-read guard; now write-only by design | Historical interface ambiguity around READ resolved; no current policy-layer mixing after cleanup | Keep with constraints | Keep low-level only; do not reintroduce read-path or throttling policy here without separate design |"
if old_nvram_row not in audit:
    raise SystemExit("FB_NVRAM_Manager row not found in audit")
audit = audit.replace(old_nvram_row, new_nvram_row, 1)

insert_after = new_nvram_row + "\n"
persist_rows = """| FB_Persist_Builder | REVIEWED | Persistence / Diagnostics / History | Builds `ST_Persist` from runtime state and mirrors it into `GVL_PERSISTENT` | Still coupled to `GVL_STATE` directly, but responsibility is now narrow and explicit | Keep with constraints | Keep as persistence builder only; consider future interface decoupling after wider architecture audit |
| FB_Persist_Pipeline | REVIEWED | Persistence / Diagnostics / History | Serializes persist struct, applies single throttling policy, and triggers controlled NVRAM write | No critical current violation after `Apply_Settings` and throttling fixes | Keep | Preserve as the only persistence write-policy layer |"""
if "FB_Persist_Builder" not in audit:
    audit = audit.replace(insert_after, insert_after + persist_rows + "\n", 1)

priority_anchor = "## 5. Initial priority review queue\n"
priority_prefix = """## 5. Persistence checkpoint note

As of the current repository state:
- persistence compile checkpoint is achieved
- `FB_Persist_Builder`, `FB_Persist_Pipeline`, and `FB_NVRAM_Manager` have been brought into a consistent write-path architecture
- `GVL_PERSISTENT` remains the primary recovery source
- NVRAM remains a secondary mirror layer

---

## 5. Initial priority review queue
"""
if priority_anchor not in audit:
    raise SystemExit("Priority queue anchor not found in audit")
audit = audit.replace(priority_anchor, priority_prefix, 1)

audit_path.write_text(audit, encoding="utf-8")

print("OK: aligned docs with current implemented persistence and health status")
