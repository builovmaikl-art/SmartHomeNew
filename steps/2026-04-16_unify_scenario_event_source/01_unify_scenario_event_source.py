from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

old_block = """ELSIF GVL_STATUS.G_Current_Scenario <> GVL_STATUS.G_Previous_Scenario THEN
    L_History_Event.event_code := 1001; // Scenario transition
    L_History_Event.event_value := TO_REAL(GVL_STATUS.G_Current_Scenario);
"""

new_block = """ELSIF GVL_STATUS.G_Current_Scenario <> GVL_STATUS.G_Previous_Scenario THEN
    L_History_Event.event_code := 1001; // Scenario transition
    L_History_Event.event_value := TO_REAL(GVL_STATUS.G_Current_Scenario);

    fbLogEvent(
        VI_Event_Type := 1,
        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
        VI_Param1 := TO_UDINT(L_Scenario_Source),
        VI_Param2 := TO_UDINT(GVL_STATUS.G_Current_Scenario)
    );
"""

if old_block not in text:
    raise SystemExit("History scenario block not found")

text = text.replace(old_block, new_block, 1)

# Удаляем отдельный блок event logging (он теперь не нужен)
remove_block = """// === EVENT LOGGING: SCENARIO CHANGE (DETERMINISTIC) ===
IF GVL_STATUS.G_Current_Scenario <> GVL_STATUS.G_Previous_Scenario THEN
    fbLogEvent(
        VI_Event_Type := 1,
        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
        VI_Param1 := TO_UDINT(L_Scenario_Source),
        VI_Param2 := TO_UDINT(GVL_STATUS.G_Current_Scenario)
    );
END_IF;
"""

if remove_block in text:
    text = text.replace(remove_block, "")

path.write_text(text, encoding="utf-8")
print("OK: unified scenario event source (history + log)")
