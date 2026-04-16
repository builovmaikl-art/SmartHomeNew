from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

old = """IF NOT fbScenarioGuard.VO_Transition_Allowed THEN
    GVL_STATUS.G_Diagnostics.HMI_Last_Message := CONCAT('Scenario guard: ', fbScenarioGuard.VO_Reason);
END_IF;

fbScenarioManager(
"""

new = """IF NOT fbScenarioGuard.VO_Transition_Allowed THEN
    GVL_STATUS.G_Diagnostics.HMI_Last_Message := CONCAT('Scenario guard: ', fbScenarioGuard.VO_Reason);
    L_Scenario_Intent := GVL_STATUS.G_Current_Scenario;
END_IF;

fbScenarioManager(
"""

if old not in text:
    raise SystemExit("Diagnostic-only guard block not found")

text = text.replace(old, new, 1)
path.write_text(text, encoding="utf-8")
print("OK: soft scenario guard enforcement enabled")
