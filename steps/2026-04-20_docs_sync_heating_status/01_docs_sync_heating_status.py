from pathlib import Path
import re

files = [
    Path("HEATING_CHECKPOINT_2026-04-20.md"),
    Path("docs/REFACTOR_PLAN_ARCH_ALIGNMENT.md"),
    Path("docs/FB_INVENTORY_AUDIT.md"),
]

for f in files:
    if not f.exists():
        raise SystemExit(f"Missing file: {f}")

# -------------------------------------------------
# 1. Update root heating checkpoint
# -------------------------------------------------
p = Path("HEATING_CHECKPOINT_2026-04-20.md")
text = p.read_text(encoding="utf-8")

extra = """

## Heating evolution status update

The heating stack has advanced beyond the earlier checkpoint and now includes:

- request flags in `GVL_STATE`
- arbitration / stabilization in `PRG_Heating`
- target temperature injection in `FB_Heating_System_Manager`
- multi-zone adaptive correction
- weighted adaptive correction
- floor-vs-air adaptive bias
- zone priority weighting

## Current practical interpretation

The current heating path is no longer only a request bridge.
It is now a layered control path:

`Rule Engine -> PRG_System -> GVL_STATE requests -> PRG_Heating arbitration/stabilization -> FB_Heating_System_Manager adaptive weighted correction`

## Recommended next engineering step

Do not merge all remaining adaptation ideas into a single mega-step.
Prefer 2-3 large controlled packages:

1. adaptive v3: per-zone hysteresis / time stability
2. policy refinement: freeze/preheat/normal semantics cleanup
3. optional later tuning: zone classes / comfort policy / learning

"""

if "Heating evolution status update" not in text:
    text += extra

p.write_text(text, encoding="utf-8")

# -------------------------------------------------
# 2. Update refactor plan
# -------------------------------------------------
p = Path("docs/REFACTOR_PLAN_ARCH_ALIGNMENT.md")
text = p.read_text(encoding="utf-8")

if "heating architecture checkpoint" not in text.lower():
    insert_anchor = "### Current verified implementation checkpoints\n"
    insert_block = """### Current verified implementation checkpoints

Additional verified heating architecture checkpoint:
- request flags are routed through `GVL_STATE`
- `PRG_Heating` performs arbitration / stabilization
- `FB_Heating_System_Manager` now includes adaptive zone-aware correction
- heating adaptive layer already includes weighted correction, floor-vs-air bias, and zone priority weighting

"""
    text = re.sub(r"### Current verified implementation checkpoints\s*", insert_block, text, count=1)

if "Stage 7" in text and "Heating adaptation is now beyond basic orchestration" not in text:
    text += """

## Heating adaptation note

Heating adaptation is now beyond basic orchestration.
The next safe step is not a full redesign, but controlled refinement:
- per-zone hysteresis / time stability
- semantic cleanup of freeze/preheat/normal policy
- only then possible deeper adaptive intelligence

"""

p.write_text(text, encoding="utf-8")

# -------------------------------------------------
# 3. Update FB inventory audit
# -------------------------------------------------
p = Path("docs/FB_INVENTORY_AUDIT.md")
text = p.read_text(encoding="utf-8")

old_row_pattern = r"\| FB_Heating_System_Manager \|.*"
new_row = "| FB_Heating_System_Manager | REVIEWED | Heating / Control / Policy | Live heating manager now sits behind request/arbitration/stabilization layers and includes adaptive weighted zone-aware correction | Complexity has increased; future changes must preserve current layering and avoid random direct writes | Keep | Continue with controlled refinement only (per-zone hysteresis, policy cleanup, no mega-refactor) |"

if re.search(old_row_pattern, text):
    text = re.sub(old_row_pattern, new_row, text, count=1)
else:
    # append if row not found
    text += "\n" + new_row + "\n"

if "## 5. Heating checkpoint note" not in text:
    text += """

## 5. Heating checkpoint note

Current heating status:
- request routing is active through `GVL_STATE`
- arbitration / stabilization lives in `PRG_Heating`
- adaptive weighted correction lives in `FB_Heating_System_Manager`
- current contour is compile-verified and should be evolved in large controlled packages, not one mega-step

"""

p.write_text(text, encoding="utf-8")

print("OK: docs synced to real heating status")
