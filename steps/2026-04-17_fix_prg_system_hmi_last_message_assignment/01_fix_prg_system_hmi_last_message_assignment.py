from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

old = "    GVL_STATUS.G_Diagnostics.HMI_Last_Message := CONCAT('Scenario guard: ', fbScenarioGuard.VO_Reason);\n"
new = "    GVL_GATEWAY.G_Gateway_HMI_Status_Message := CONCAT('Scenario guard: ', fbScenarioGuard.VO_Reason);\n"

if old not in text:
    raise SystemExit("Target assignment not found in PRG_System.st")

text = text.replace(old, new, 1)
path.write_text(text, encoding="utf-8")
print("OK: redirected scenario guard HMI message to GVL_GATEWAY.G_Gateway_HMI_Status_Message")
