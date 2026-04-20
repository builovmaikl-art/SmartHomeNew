from pathlib import Path

prg_path = Path("PRG_Heating.st")
text = prg_path.read_text(encoding="utf-8")

old = """fbHeatingManager(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
"""

new = """fbHeatingManager(
    VI_Command := fbRuleEngine.VO_Heating_Command,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
"""

if "VI_Command := fbRuleEngine.VO_Heating_Command" in text:
    print("OK: live heating wiring already present")
else:
    if old not in text:
        raise SystemExit("fbHeatingManager call anchor not found in PRG_Heating.st")
    text = text.replace(old, new, 1)
    prg_path.write_text(text, encoding="utf-8")
    print("OK: added live VI_Command wiring to PRG_Heating.st")
