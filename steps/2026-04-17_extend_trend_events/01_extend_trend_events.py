from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

old_block = """
IF L_Trend_Write AND NOT L_Trend_Write_Prev THEN
    L_Trend_Event.event_code := 1001;
    L_Trend_Event.event_value := L_Trend_Avg;
    L_Trend_Event.zone_id := 0;
    L_Trend_Event.operator_id := '';
    L_History_Write_Event := TRUE;
    L_History_Event := L_Trend_Event;
END_IF;
"""

new_block = """
IF L_Trend_Write AND NOT L_Trend_Write_Prev THEN

    // === AVERAGE ===
    L_Trend_Event.event_code := 1001;
    L_Trend_Event.event_value := L_Trend_Avg;
    L_Trend_Event.zone_id := 0;
    L_Trend_Event.operator_id := '';
    L_History_Write_Event := TRUE;
    L_History_Event := L_Trend_Event;

    // === MIN ===
    L_Trend_Event.event_code := 1002;
    L_Trend_Event.event_value := L_Trend_Min;
    L_History_Write_Event := TRUE;
    L_History_Event := L_Trend_Event;

    // === MAX ===
    L_Trend_Event.event_code := 1003;
    L_Trend_Event.event_value := L_Trend_Max;
    L_History_Write_Event := TRUE;
    L_History_Event := L_Trend_Event;

    // === TREND DIRECTION ===
    IF L_Trend_Up THEN
        L_Trend_Event.event_code := 1004;
        L_Trend_Event.event_value := 1.0;
        L_History_Write_Event := TRUE;
        L_History_Event := L_Trend_Event;
    ELSIF L_Trend_Down THEN
        L_Trend_Event.event_code := 1005;
        L_Trend_Event.event_value := -1.0;
        L_History_Write_Event := TRUE;
        L_History_Event := L_Trend_Event;
    END_IF;

END_IF;
"""

if old_block not in text:
    raise SystemExit("Trend history block not found")

text = text.replace(old_block, new_block, 1)

path.write_text(text, encoding="utf-8")
print("OK: extended trend events (avg/min/max/direction)")
