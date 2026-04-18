from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

old = """// === TREND CHANNEL 2 (FLOOR TEMP) ===
IF GVL_Trend.G_Trend_Channel2_Enabled THEN

    GVL_Trend.G_Trend_Buffer_2_Index := GVL_Trend.G_Trend_Buffer_2_Index + 1;
    IF GVL_Trend.G_Trend_Buffer_2_Index > 50 THEN
        GVL_Trend.G_Trend_Buffer_2_Index := 1;
    END_IF;

    GVL_Trend.G_Trend_Buffer_2[GVL_Trend.G_Trend_Buffer_2_Index] := GVL_STATE.G_Floor_Temp;
    GVL_Trend.G_Trend_Buffer_2_Timestamps[GVL_Trend.G_Trend_Buffer_2_Index] := GVL_STATUS.G_System_Time_MS;

    IF GVL_Trend.G_Trend_Buffer_2_Valid_Count < 50 THEN
        GVL_Trend.G_Trend_Buffer_2_Valid_Count := GVL_Trend.G_Trend_Buffer_2_Valid_Count + 1;
    ELSE
        GVL_Trend.G_Trend_Buffer_2_Is_Wrapped := TRUE;
    END_IF;

    GVL_Trend.G_Trend_Channel2_Param_Type := 2; // TEMP_FLOOR

END_IF;
"""

new = """// === TREND CHANNEL 2 (FLOOR TEMP, SHARED INDEX) ===
IF GVL_Trend.G_Trend_Channel2_Enabled THEN

    GVL_Trend.G_Trend_Buffer_2_Index := GVL_Trend.G_Trend_Buffer_Index;
    GVL_Trend.G_Trend_Buffer_2[GVL_Trend.G_Trend_Buffer_2_Index] := GVL_STATE.G_Floor_Temp;
    GVL_Trend.G_Trend_Buffer_2_Timestamps[GVL_Trend.G_Trend_Buffer_2_Index] := GVL_STATUS.G_System_Time_MS;

    IF GVL_Trend.G_Trend_Buffer_2_Valid_Count < 50 THEN
        GVL_Trend.G_Trend_Buffer_2_Valid_Count := GVL_Trend.G_Trend_Buffer_2_Valid_Count + 1;
    ELSE
        GVL_Trend.G_Trend_Buffer_2_Is_Wrapped := TRUE;
    END_IF;

    GVL_Trend.G_Trend_Channel2_Param_Type := 2; // TEMP_FLOOR

END_IF;
"""

if old not in text:
    raise SystemExit("Current channel 2 block not found exactly; aborting without changes")

text = text.replace(old, new, 1)
path.write_text(text, encoding="utf-8")
print("OK: channel 2 synced to shared primary index")
