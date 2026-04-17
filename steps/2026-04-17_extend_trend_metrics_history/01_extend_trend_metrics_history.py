from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

var_block = """
    // === TREND METRICS EXTENDED ===
    L_Trend_Event_Code : WORD;
    L_Trend_Event_Value : REAL;
"""

if "TREND METRICS EXTENDED" not in text:
    text = text.replace("VAR\n", "VAR\n" + var_block, 1)

old = """
// === TREND → HISTORY WRITE (EDGE) ===
L_Trend_Write := (L_Trend_Data.record_count > 0);

IF L_Trend_Write AND NOT L_Trend_Write_Prev THEN
    L_Trend_Event.event_code := 1001;
    L_Trend_Event.event_value := L_Trend_Data.average_value;
    L_Trend_Event.zone_id := 0;
    L_Trend_Event.operator_id := '';
END_IF;

L_Trend_Write_Prev := L_Trend_Write;
"""

new = """
// === TREND → HISTORY WRITE (EDGE, EXTENDED METRICS) ===
L_Trend_Write := (L_Trend_Data.record_count > 0);

IF L_Trend_Write AND NOT L_Trend_Write_Prev THEN
    // Event code selection:
    // 1001 = average
    // 1002 = min
    // 1003 = max
    // 1004 = trend up
    // 1005 = trend down

    L_Trend_Event_Code := 1001;
    L_Trend_Event_Value := L_Trend_Data.average_value;

    IF L_Trend_Data.min_value < L_Trend_Data.average_value THEN
        L_Trend_Event_Code := 1002;
        L_Trend_Event_Value := L_Trend_Data.min_value;
    END_IF;

    IF L_Trend_Data.max_value > L_Trend_Data.average_value THEN
        L_Trend_Event_Code := 1003;
        L_Trend_Event_Value := L_Trend_Data.max_value;
    END_IF;

    IF L_Trend_Data.trend_up THEN
        L_Trend_Event_Code := 1004;
        L_Trend_Event_Value := 1.0;
    ELSIF L_Trend_Data.trend_down THEN
        L_Trend_Event_Code := 1005;
        L_Trend_Event_Value := -1.0;
    END_IF;

    L_Trend_Event.event_code := L_Trend_Event_Code;
    L_Trend_Event.event_value := L_Trend_Event_Value;
    L_Trend_Event.zone_id := 0;
    L_Trend_Event.operator_id := '';
END_IF;

L_Trend_Write_Prev := L_Trend_Write;
"""

if old in text:
    text = text.replace(old, new, 1)
else:
    raise SystemExit("Old trend edge block not found in PRG_System.st")

path.write_text(text, encoding="utf-8")
print("OK: extended trend metrics history block applied")
