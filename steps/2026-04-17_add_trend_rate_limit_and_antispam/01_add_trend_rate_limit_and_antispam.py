from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

var_anchor = "    L_Trend_Down : BOOL;\n"
var_insert = """    L_Trend_Last_Write_MS : UDINT;
    L_Trend_Last_Written_Avg : REAL;
    L_Trend_Write_Allowed : BOOL;
"""
if var_anchor not in text:
    raise SystemExit("Trend var anchor not found")
if "L_Trend_Last_Write_MS : UDINT;" not in text:
    text = text.replace(var_anchor, var_anchor + var_insert, 1)

old = """// === TREND → HISTORY WRITE (EDGE, SAFE MVP) ===
L_Trend_Write := (L_Trend_Data.record_count > 0);

IF L_Trend_Write AND NOT L_Trend_Write_Prev THEN
    L_Trend_Event.event_code := 1001;
    IF L_Trend_Data.record_count > 0 THEN
        L_Trend_Event.event_value := L_Trend_Avg;
    ELSE
        L_Trend_Event.event_value := 0.0;
    END_IF;
    L_Trend_Event.zone_id := 0;
    L_Trend_Event.operator_id := '';
    L_History_Write_Event := TRUE;
    L_History_Event := L_Trend_Event;
END_IF;

L_Trend_Write_Prev := L_Trend_Write;
"""

new = """// === TREND → HISTORY WRITE (RATE-LIMITED SAFE MVP) ===
L_Trend_Write := (L_Trend_Data.record_count > 0);
L_Trend_Write_Allowed := FALSE;

IF L_Trend_Write AND NOT L_Trend_Write_Prev THEN
    IF (L_Trend_Last_Write_MS = 0) OR
       ((GVL_STATUS.G_System_Time_MS - L_Trend_Last_Write_MS) >= GVL_CONSTANTS.C_MS_IN_HOUR) THEN
        IF ABS(L_Trend_Avg - L_Trend_Last_Written_Avg) >= 0.5 THEN
            L_Trend_Write_Allowed := TRUE;
        END_IF;
    END_IF;

    IF L_Trend_Write_Allowed THEN
        L_Trend_Event.event_code := 1001;
        L_Trend_Event.event_value := L_Trend_Avg;
        L_Trend_Event.zone_id := 0;
        L_Trend_Event.operator_id := '';
        L_History_Write_Event := TRUE;
        L_History_Event := L_Trend_Event;

        L_Trend_Last_Write_MS := GVL_STATUS.G_System_Time_MS;
        L_Trend_Last_Written_Avg := L_Trend_Avg;
    END_IF;
END_IF;

L_Trend_Write_Prev := L_Trend_Write;
"""

if old not in text:
    raise SystemExit("Safe MVP trend history block not found")

text = text.replace(old, new, 1)
path.write_text(text, encoding="utf-8")
print("OK: added trend rate limit and anti-spam logic")
