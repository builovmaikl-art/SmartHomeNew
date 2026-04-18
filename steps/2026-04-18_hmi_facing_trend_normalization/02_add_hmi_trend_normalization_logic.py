from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

block = """
// === TREND HMI NORMALIZATION ===
IF GVL_Trend.G_Trend_Selected_Channel = 2 AND GVL_Trend.G_Trend_Channel2_Enabled THEN
    GVL_Trend.G_Trend_Active_Param_Type := GVL_Trend.G_Trend_Channel2_Param_Type;
    GVL_Trend.G_Trend_Active_Label := GVL_Trend.G_Trend_Channel2_Label;
ELSE
    GVL_Trend.G_Trend_Active_Param_Type := GVL_Trend.G_Trend_Param_Type;
    GVL_Trend.G_Trend_Active_Label := GVL_Trend.G_Trend_Channel1_Label;
END_IF;
"""

if "// === TREND HMI NORMALIZATION ===" not in text:
    marker = "// === TREND → HISTORY WRITE"
    if marker not in text:
        raise SystemExit("Trend history marker not found in PRG_System.st")
    text = text.replace(marker, block + "\n" + marker, 1)

path.write_text(text, encoding="utf-8")
print("OK: added HMI-facing trend normalization logic to PRG_System")
