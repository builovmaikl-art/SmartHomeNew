from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

block = """
// === TREND BUFFER UPDATE ===
GVL_Trend.G_Trend_Buffer_Index := GVL_Trend.G_Trend_Buffer_Index + 1;
IF GVL_Trend.G_Trend_Buffer_Index > 50 THEN
    GVL_Trend.G_Trend_Buffer_Index := 1;
END_IF;

GVL_Trend.G_Trend_Buffer[GVL_Trend.G_Trend_Buffer_Index] := L_Trend_Avg;
"""

if "// === TREND BUFFER UPDATE ===" not in text:
    text = text.replace(
        "// === TREND → GVL FOR HMI ===",
        "// === TREND → GVL FOR HMI ===\n" + block
    )

path.write_text(text, encoding="utf-8")
print("OK: added trend buffer logic")
