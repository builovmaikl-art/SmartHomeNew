from pathlib import Path

path = Path("GVL_Trend.gvl")
text = path.read_text(encoding="utf-8")

insert = """
    // === HMI-FACING TREND NORMALIZATION ===
    G_Trend_Active_Param_Type : BYTE;
    G_Trend_Active_Label : STRING(32);
    G_Trend_Channel1_Label : STRING(32) := 'Outdoor Temp';
    G_Trend_Channel2_Label : STRING(32) := 'Floor Temp';
"""

if "G_Trend_Active_Param_Type" not in text:
    text = text.replace("END_VAR", insert + "\nEND_VAR")

path.write_text(text, encoding="utf-8")
print("OK: added HMI-facing trend normalization fields to GVL_Trend")
