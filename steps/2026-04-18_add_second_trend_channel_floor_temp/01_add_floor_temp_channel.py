from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

block = """
// === TREND CHANNEL 2 (FLOOR TEMP) ===
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

if "// === TREND CHANNEL 2 (FLOOR TEMP) ===" not in text:
    anchor = "// === TREND BUFFER UPDATE ==="
    if anchor not in text:
        raise SystemExit("Trend buffer update anchor not found")
    text = text.replace(anchor, anchor + "\n" + block, 1)

path.write_text(text, encoding="utf-8")
print("OK: added second trend channel (floor temp)")
