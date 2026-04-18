from pathlib import Path

# ------------------------------------------------------------
# 1) Extend ST_System_Diagnostics.dut with counters
# ------------------------------------------------------------
dut = Path("ST_System_Diagnostics.dut")
text = dut.read_text(encoding="utf-8")

anchor = """    Sensor_Shadow_Quality_Text : STRING(160);
"""
insert = """    Sensor_Shadow_Quality_Text : STRING(160);

    Sensor_Shadow_CO_Fallback_Count : UDINT;
    Sensor_Shadow_CO_Recovery_Count : UDINT;
    Sensor_Shadow_Methane_Fallback_Count : UDINT;
    Sensor_Shadow_Methane_Recovery_Count : UDINT;
    Sensor_Shadow_Smoke_Fallback_Count : UDINT;
    Sensor_Shadow_Smoke_Recovery_Count : UDINT;
    Sensor_Shadow_Total_Fallback_Count : UDINT;
    Sensor_Shadow_Total_Recovery_Count : UDINT;
"""

if "Sensor_Shadow_CO_Fallback_Count" not in text:
    if anchor not in text:
        raise SystemExit("Diagnostics anchor not found in ST_System_Diagnostics.dut")
    text = text.replace(anchor, insert, 1)

dut.write_text(text, encoding="utf-8")

# ------------------------------------------------------------
# 2) Patch PRG_System.st event logging block
# ------------------------------------------------------------
prg = Path("PRG_System.st")
text = prg.read_text(encoding="utf-8")

repls = [
    (
"""IF (NOT GVL_Safety_Selector.G_Use_Shadow_CO) AND L_Shadow_CO_Enabled_Prev THEN
    fbLogEvent(
        VI_Event_Type := 21,
        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
        VI_Param1 := 2101,
        VI_Param2 := 0
    );
END_IF;""",
"""IF (NOT GVL_Safety_Selector.G_Use_Shadow_CO) AND L_Shadow_CO_Enabled_Prev THEN
    fbLogEvent(
        VI_Event_Type := 21,
        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
        VI_Param1 := 2101,
        VI_Param2 := 0
    );
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Fallback_Count := GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Fallback_Count + 1;
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Fallback_Count := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Fallback_Count + 1;
END_IF;"""
    ),
    (
"""IF GVL_Safety_Selector.G_Use_Shadow_CO AND (NOT L_Shadow_CO_Enabled_Prev) THEN
    fbLogEvent(
        VI_Event_Type := 22,
        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
        VI_Param1 := 2102,
        VI_Param2 := 1
    );
END_IF;""",
"""IF GVL_Safety_Selector.G_Use_Shadow_CO AND (NOT L_Shadow_CO_Enabled_Prev) THEN
    fbLogEvent(
        VI_Event_Type := 22,
        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
        VI_Param1 := 2102,
        VI_Param2 := 1
    );
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Recovery_Count := GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Recovery_Count + 1;
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Recovery_Count := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Recovery_Count + 1;
END_IF;"""
    ),
    (
"""IF (NOT GVL_Safety_Selector.G_Use_Shadow_Methane) AND L_Shadow_Methane_Enabled_Prev THEN
    fbLogEvent(
        VI_Event_Type := 23,
        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
        VI_Param1 := 2111,
        VI_Param2 := 0
    );
END_IF;""",
"""IF (NOT GVL_Safety_Selector.G_Use_Shadow_Methane) AND L_Shadow_Methane_Enabled_Prev THEN
    fbLogEvent(
        VI_Event_Type := 23,
        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
        VI_Param1 := 2111,
        VI_Param2 := 0
    );
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Fallback_Count := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Fallback_Count + 1;
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Fallback_Count := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Fallback_Count + 1;
END_IF;"""
    ),
    (
"""IF GVL_Safety_Selector.G_Use_Shadow_Methane AND (NOT L_Shadow_Methane_Enabled_Prev) THEN
    fbLogEvent(
        VI_Event_Type := 24,
        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
        VI_Param1 := 2112,
        VI_Param2 := 1
    );
END_IF;""",
"""IF GVL_Safety_Selector.G_Use_Shadow_Methane AND (NOT L_Shadow_Methane_Enabled_Prev) THEN
    fbLogEvent(
        VI_Event_Type := 24,
        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
        VI_Param1 := 2112,
        VI_Param2 := 1
    );
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Recovery_Count := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Recovery_Count + 1;
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Recovery_Count := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Recovery_Count + 1;
END_IF;"""
    ),
    (
"""IF (NOT GVL_Safety_Selector.G_Use_Shadow_Smoke) AND L_Shadow_Smoke_Enabled_Prev THEN
    fbLogEvent(
        VI_Event_Type := 25,
        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
        VI_Param1 := 2121,
        VI_Param2 := 0
    );
END_IF;""",
"""IF (NOT GVL_Safety_Selector.G_Use_Shadow_Smoke) AND L_Shadow_Smoke_Enabled_Prev THEN
    fbLogEvent(
        VI_Event_Type := 25,
        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
        VI_Param1 := 2121,
        VI_Param2 := 0
    );
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Fallback_Count := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Fallback_Count + 1;
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Fallback_Count := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Fallback_Count + 1;
END_IF;"""
    ),
    (
"""IF GVL_Safety_Selector.G_Use_Shadow_Smoke AND (NOT L_Shadow_Smoke_Enabled_Prev) THEN
    fbLogEvent(
        VI_Event_Type := 26,
        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
        VI_Param1 := 2122,
        VI_Param2 := 1
    );
END_IF;""",
"""IF GVL_Safety_Selector.G_Use_Shadow_Smoke AND (NOT L_Shadow_Smoke_Enabled_Prev) THEN
    fbLogEvent(
        VI_Event_Type := 26,
        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
        VI_Param1 := 2122,
        VI_Param2 := 1
    );
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Recovery_Count := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Recovery_Count + 1;
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Recovery_Count := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Recovery_Count + 1;
END_IF;"""
    ),
]

for old, new in repls:
    if old not in text:
        raise SystemExit("Expected event logging pattern not found in PRG_System.st")
    text = text.replace(old, new, 1)

prg.write_text(text, encoding="utf-8")
print("OK: added shadow policy event aggregation counters")
