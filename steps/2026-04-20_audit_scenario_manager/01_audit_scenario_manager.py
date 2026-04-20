from pathlib import Path
import re

p = Path("FB_Scenario_Manager.st")
if not p.exists():
    raise SystemExit("FB_Scenario_Manager.st not found")

text = p.read_text(encoding="utf-8")

report = []

gvl_refs = sorted(set(re.findall(r"GVL_[A-Z0-9_]+\.", text)))
vo_refs = sorted(set(re.findall(r"VO_[A-Za-z0-9_]+", text)))
vio_refs = sorted(set(re.findall(r"VIO_[A-Za-z0-9_]+", text)))
actuator_words = []
for w in ["Valve", "Pump", "Heater", "Lighting", "Blind", "Socket", "Alarm", "Open", "Close"]:
    if w in text:
        actuator_words.append(w)

report.append("=== GVL DIRECT ACCESS ===")
report.append("\n".join(gvl_refs) if gvl_refs else "NONE")

report.append("\n=== OUTPUT SIGNALS (VO_*) ===")
report.append("\n".join(vo_refs) if vo_refs else "NONE")

report.append("\n=== INOUT SIGNALS (VIO_*) ===")
report.append("\n".join(vio_refs) if vio_refs else "NONE")

report.append("\n=== POSSIBLE ACTUATOR SIGNALS ===")
report.append(", ".join(actuator_words) if actuator_words else "NONE")

report.append(f"\n=== TOTAL ASSIGNMENTS === {len(re.findall(r':=\\s*', text))}")
report.append(f"=== TIMERS === {len(re.findall(r'FB_System_Timer', text))}")

Path("диагностика/scenario_manager_audit.txt").write_text("\n".join(report), encoding="utf-8")
print("OK: scenario manager audit complete")
