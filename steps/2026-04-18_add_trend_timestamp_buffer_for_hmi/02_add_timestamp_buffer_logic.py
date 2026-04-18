from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

old = "GVL_Trend.G_Trend_Buffer[GVL_Trend.G_Trend_Buffer_Index] := L_Trend_Avg;\n"
new = """GVL_Trend.G_Trend_Buffer[GVL_Trend.G_Trend_Buffer_Index] := L_Trend_Avg;
GVL_Trend.G_Trend_Buffer_Timestamps[GVL_Trend.G_Trend_Buffer_Index] := GVL_STATUS.G_System_Time_MS;
"""

if old not in text:
    raise SystemExit("Trend buffer write line not found in PRG_System.st")

if "G_Trend_Buffer_Timestamps" not in text:
    text = text.replace(old, new, 1)

path.write_text(text, encoding="utf-8")
print("OK: added timestamp writes to trend buffer logic")
