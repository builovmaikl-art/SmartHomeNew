from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

# 1) Remove duplicate trend-write declaration block if present
dup_block = """    // === TREND → HISTORY BRIDGE ===
    L_Trend_Event : ST_History_Record;
    L_Trend_Write : BOOL;
"""
if dup_block in text:
    text = text.replace(dup_block, "    // === TREND → HISTORY BRIDGE ===\n    L_Trend_Event : ST_History_Record;\n", 1)

# 2) Add analyzer result vars right after L_Trend_Data if missing
anchor = "    L_Trend_Data : ST_Trend_Data;\n"
insert = """    L_Trend_Average : REAL;
    L_Trend_Min : REAL;
    L_Trend_Max : REAL;
    L_Trend_Up : BOOL;
    L_Trend_Down : BOOL;
"""
if anchor not in text:
    raise SystemExit("Trend data anchor not found")
if "L_Trend_Average : REAL;" not in text:
    text = text.replace(anchor, anchor + insert, 1)

# 3) Append exact execution block near end if missing
block = """
// === TREND EXECUTION (MVP) ===
L_Trend_Logger(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Config := (
        param_type := 1,
        zone_id := 0,
        enabled := TRUE,
        deviation_threshold_percent := 1.0,
        history_days := 1
    ),
    VI_Current_Value := GVL_STATE.G_Outdoor_Temp
);

L_Trend_Data := L_Trend_Logger.VO_Data;

L_Trend_Analyzer(
    VI_Count := INT(L_Trend_Data.record_count),
    VI_Data := L_Trend_Data.values,
    VO_Average => L_Trend_Average,
    VO_Max => L_Trend_Max,
    VO_Min => L_Trend_Min,
    VO_Trend_Up => L_Trend_Up,
    VO_Trend_Down => L_Trend_Down
);

// === TREND → HISTORY WRITE (EDGE, EXTENDED METRICS) ===
L_Trend_Write := (L_Trend_Data.record_count > 0);

IF L_Trend_Write AND NOT L_Trend_Write_Prev THEN
    L_Trend_Event.event_code := 1001;
    L_Trend_Event.event_value := L_Trend_Average;
    L_Trend_Event.zone_id := 0;
    L_Trend_Event.operator_id := '';

    IF L_Trend_Min < L_Trend_Average THEN
        L_Trend_Event.event_code := 1002;
        L_Trend_Event.event_value := L_Trend_Min;
    END_IF;

    IF L_Trend_Max > L_Trend_Average THEN
        L_Trend_Event.event_code := 1003;
        L_Trend_Event.event_value := L_Trend_Max;
    END_IF;

    IF L_Trend_Up THEN
        L_Trend_Event.event_code := 1004;
        L_Trend_Event.event_value := 1.0;
    ELSIF L_Trend_Down THEN
        L_Trend_Event.event_code := 1005;
        L_Trend_Event.event_value := -1.0;
    END_IF;

    L_History_Write_Event := TRUE;
    L_History_Event := L_Trend_Event;
END_IF;

L_Trend_Write_Prev := L_Trend_Write;
"""

if "// === TREND EXECUTION (MVP) ===" not in text:
    marker = "\n// >>> BULK_SYNC_ANCHOR: PRG_System <<<\n"
    if marker not in text:
        raise SystemExit("PRG_System bulk sync anchor not found")
    text = text.replace(marker, "\n" + block + marker, 1)

path.write_text(text, encoding="utf-8")
print("OK: fixed trend execution and extended metrics with exact field names")
