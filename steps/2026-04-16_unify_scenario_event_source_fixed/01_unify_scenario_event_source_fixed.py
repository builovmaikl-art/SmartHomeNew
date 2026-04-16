from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

history_old = """ELSIF GVL_STATUS.G_Current_Scenario <> GVL_STATUS.G_Previous_Scenario THEN
    L_History_Write_Event := TRUE;
    L_History_Event.event_code := 1001; // Scenario transition
    L_History_Event.event_value := TO_REAL(GVL_STATUS.G_Current_Scenario);
    L_History_Event.unit := 4; // scenario domain
    L_History_Event.zone_id := 0;
    L_History_Event.priority := E_ALERT_PRIORITY.ALERT_PRIORITY_HIGH;
    GVL_STATUS.G_Previous_Scenario := GVL_STATUS.G_Current_Scenario;
"""

history_new = """ELSIF GVL_STATUS.G_Current_Scenario <> GVL_STATUS.G_Previous_Scenario THEN
    L_History_Write_Event := TRUE;
    L_History_Event.event_code := 1001; // Scenario transition
    L_History_Event.event_value := TO_REAL(GVL_STATUS.G_Current_Scenario);
    L_History_Event.unit := 4; // scenario domain
    L_History_Event.zone_id := 0;
    L_History_Event.priority := E_ALERT_PRIORITY.ALERT_PRIORITY_HIGH;

    fbLogEvent(
        VI_Event_Type := 1,
        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
        VI_Param1 := TO_UDINT(L_Scenario_Source),
        VI_Param2 := TO_UDINT(GVL_STATUS.G_Current_Scenario)
    );

    GVL_STATUS.G_Previous_Scenario := GVL_STATUS.G_Current_Scenario;
"""

if history_old not in text:
    raise SystemExit("Live history scenario block not found")

text = text.replace(history_old, history_new, 1)

event_block = """// === EVENT LOGGING: SCENARIO CHANGE (DETERMINISTIC) ===
IF GVL_STATUS.G_Current_Scenario <> GVL_STATUS.G_Previous_Scenario THEN
    fbLogEvent(
        VI_Event_Type := 1,
        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
        VI_Param1 := TO_UDINT(L_Scenario_Source),
        VI_Param2 := TO_UDINT(GVL_STATUS.G_Current_Scenario)
    );
END_IF;

"""

if event_block not in text:
    raise SystemExit("Deterministic scenario event block not found")

text = text.replace(event_block, "", 1)

path.write_text(text, encoding="utf-8")
print("OK: unified scenario event source into history branch")
