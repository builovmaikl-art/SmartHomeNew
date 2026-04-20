from pathlib import Path
import re

rule = Path("FB_Rule_Engine.st")
if not rule.exists():
    raise SystemExit("FB_Rule_Engine.st not found")

text = rule.read_text(encoding="utf-8")

report = []

# -------------------------------------------------
# 1. Detect direct GVL writes (architectural violation)
# -------------------------------------------------
gvl_writes = re.findall(r"GVL_[A-Z0-9_]+\.", text)
report.append("=== GVL DIRECT ACCESS ===")
report.append("\n".join(sorted(set(gvl_writes))) if gvl_writes else "NONE")

# -------------------------------------------------
# 2. Detect actuator-like writes (danger)
# -------------------------------------------------
actuator_patterns = [
    "Valve",
    "Pump",
    "Heater",
    "Alarm",
    "Open",
    "Close"
]

report.append("\n=== POSSIBLE ACTUATOR SIGNALS ===")
hits = []
for p in actuator_patterns:
    if p in text:
        hits.append(p)
report.append(", ".join(hits) if hits else "NONE")

# -------------------------------------------------
# 3. Detect outputs (intent signals)
# -------------------------------------------------
outputs = re.findall(r"VO_[A-Za-z0-9_]+", text)
report.append("\n=== OUTPUT SIGNALS (VO_*) ===")
report.append("\n".join(sorted(set(outputs))) if outputs else "NONE")

# -------------------------------------------------
# 4. Check for side-effects (writes outside outputs)
# -------------------------------------------------
assignments = re.findall(r":=\s*", text)
report.append(f"\n=== TOTAL ASSIGNMENTS === {len(assignments)}")

# -------------------------------------------------
# 5. Detect timer / state logic (complexity)
# -------------------------------------------------
timers = re.findall(r"FB_System_Timer", text)
report.append(f"\n=== TIMERS === {len(timers)}")

# -------------------------------------------------
# 6. Save report
# -------------------------------------------------
out = Path("диагностика/rule_engine_audit.txt")
out.write_text("\n".join(report), encoding="utf-8")

print("OK: rule engine audit complete")
