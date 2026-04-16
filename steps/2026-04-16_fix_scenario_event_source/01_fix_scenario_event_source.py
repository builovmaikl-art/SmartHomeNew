from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

old = """// === EVENT LOGGING: SCENARIO CHANGE ===
IF L_Scenario_Changed THEN
    fbLogEvent(
        VI_Event_Type := 1,
        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
        VI_Param1 := TO_UDINT(L_Scenario_Source),
        VI_Param2 := TO_UDINT(L_Scenario_Intent)
    );
END_IF;
"""

new = """// === EVENT LOGGING: SCENARIO CHANGE (DETERMINISTIC) ===
IF GVL_STATUS.G_Current_Scenario <> GVL_STATUS.G_Previous_Scenario THEN
    fbLogEvent(
        VI_Event_Type := 1,
        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
        VI_Param1 := TO_UDINT(L_Scenario_Source),
        VI_Param2 := TO_UDINT(GVL_STATUS.G_Current_Scenario)
    );
END_IF;
"""

if old not in text:
    raise SystemExit("Scenario logging block not found")

text = text.replace(old, new, 1)

path.write_text(text, encoding="utf-8")
print("OK: scenario event logging now tied to real state transition")
