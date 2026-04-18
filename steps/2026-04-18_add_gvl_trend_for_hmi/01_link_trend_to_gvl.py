from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

link_block = """
// === TREND → GVL FOR HMI ===
GVL_Trend.G_Trend_Avg := L_Trend_Avg;
GVL_Trend.G_Trend_Min := L_Trend_Min;
GVL_Trend.G_Trend_Max := L_Trend_Max;
GVL_Trend.G_Trend_Up := L_Trend_Up;
GVL_Trend.G_Trend_Down := L_Trend_Down;
"""

if "// === TREND → GVL FOR HMI ===" not in text:
    text = text.replace(
        "// === TREND → HISTORY WRITE",
        link_block + "\n// === TREND → HISTORY WRITE"
    )

path.write_text(text, encoding="utf-8")
print("OK: linked trend data to GVL_Trend")
