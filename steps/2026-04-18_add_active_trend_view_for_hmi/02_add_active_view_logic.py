from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

block = """
// === TREND ACTIVE VIEW FOR HMI ===
IF GVL_Trend.G_Trend_Selected_Channel = 2 AND GVL_Trend.G_Trend_Channel2_Enabled THEN
    GVL_Trend.G_Trend_Active_Index := GVL_Trend.G_Trend_Buffer_2_Index;
    GVL_Trend.G_Trend_Active_Valid_Count := GVL_Trend.G_Trend_Buffer_2_Valid_Count;
    GVL_Trend.G_Trend_Active_Is_Wrapped := GVL_Trend.G_Trend_Buffer_2_Is_Wrapped;

    IF GVL_Trend.G_Trend_Buffer_2_Index >= 1 AND GVL_Trend.G_Trend_Buffer_2_Index <= 50 THEN
        GVL_Trend.G_Trend_Active_Value := GVL_Trend.G_Trend_Buffer_2[GVL_Trend.G_Trend_Buffer_2_Index];
        GVL_Trend.G_Trend_Active_Timestamp := GVL_Trend.G_Trend_Buffer_2_Timestamps[GVL_Trend.G_Trend_Buffer_2_Index];
    END_IF;
ELSE
    GVL_Trend.G_Trend_Active_Index := GVL_Trend.G_Trend_Buffer_Index;
    GVL_Trend.G_Trend_Active_Valid_Count := GVL_Trend.G_Trend_Valid_Count;
    GVL_Trend.G_Trend_Active_Is_Wrapped := GVL_Trend.G_Trend_Is_Wrapped;

    IF GVL_Trend.G_Trend_Buffer_Index >= 1 AND GVL_Trend.G_Trend_Buffer_Index <= 50 THEN
        GVL_Trend.G_Trend_Active_Value := GVL_Trend.G_Trend_Buffer[GVL_Trend.G_Trend_Buffer_Index];
        GVL_Trend.G_Trend_Active_Timestamp := GVL_Trend.G_Trend_Buffer_Timestamps[GVL_Trend.G_Trend_Buffer_Index];
    END_IF;
END_IF;
"""

if "// === TREND ACTIVE VIEW FOR HMI ===" not in text:
    marker = "// === TREND → HISTORY WRITE"
    if marker not in text:
        raise SystemExit("Trend history marker not found in PRG_System.st")
    text = text.replace(marker, block + "\n" + marker, 1)

path.write_text(text, encoding="utf-8")
print("OK: added active trend view logic to PRG_System")
