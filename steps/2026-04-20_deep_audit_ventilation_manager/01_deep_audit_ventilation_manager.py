from pathlib import Path
import re

p = Path("FB_Ventilation_System_Manager.st")
if not p.exists():
    raise SystemExit("FB_Ventilation_System_Manager.st not found")

text = p.read_text(encoding="utf-8")

report = []

# -------------------------------------------------
# 1. Exact GVL_STATE usage (critical)
# -------------------------------------------------
state_lines = []
for i, line in enumerate(text.splitlines(), 1):
    if "GVL_STATE." in line:
        state_lines.append(f"{i}: {line.strip()}")

report.append("=== GVL_STATE USAGE (EXACT LINES) ===")
report.append("\n".join(state_lines) if state_lines else "NONE")

# -------------------------------------------------
# 2. All assignments (to detect actuation)
# -------------------------------------------------
assign_lines = []
for i, line in enumerate(text.splitlines(), 1):
    if ":=" in line:
        assign_lines.append(f"{i}: {line.strip()}")

report.append("\n=== ALL ASSIGNMENTS ===")
report.append("\n".join(assign_lines) if assign_lines else "NONE")

# -------------------------------------------------
# 3. Outputs (VO_*)
# -------------------------------------------------
vo_lines = []
for i, line in enumerate(text.splitlines(), 1):
    if "VO_" in line:
        vo_lines.append(f"{i}: {line.strip()}")

report.append("\n=== VO OUTPUT USAGE ===")
report.append("\n".join(vo_lines) if vo_lines else "NONE")

# -------------------------------------------------
# 4. Heater / Fan / Safety keywords
# -------------------------------------------------
keywords = ["Fan", "Heater", "Temp", "Alarm", "Overheat", "Freeze"]
kw_hits = []
for i, line in enumerate(text.splitlines(), 1):
    for kw in keywords:
        if kw in line:
            kw_hits.append(f"{i}: {line.strip()}")
            break

report.append("\n=== CONTROL / SAFETY KEYWORDS ===")
report.append("\n".join(kw_hits) if kw_hits else "NONE")

# -------------------------------------------------
# 5. Detect sections (very rough)
# -------------------------------------------------
sections = re.findall(r"//.*", text)
report.append("\n=== COMMENT SECTIONS (STRUCTURE HINT) ===")
report.append("\n".join(sections[:50]))

# -------------------------------------------------
# 6. Save
# -------------------------------------------------
Path("диагностика/ventilation_manager_deep_audit.txt").write_text("\n".join(report), encoding="utf-8")

print("OK: deep ventilation audit complete")
