from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

old = "    GVL_Trend.G_Trend_Buffer_2[GVL_Trend.G_Trend_Buffer_2_Index] := GVL_STATE.G_Floor_Temp;\n"
new = "    GVL_Trend.G_Trend_Buffer_2[GVL_Trend.G_Trend_Buffer_2_Index] := L_FloorTemps_8[1];\n"

if old not in text:
    raise SystemExit("Expected floor temp source line not found in PRG_System.st")

text = text.replace(old, new, 1)
path.write_text(text, encoding="utf-8")
print("OK: channel 2 source changed from missing GVL_STATE.G_Floor_Temp to L_FloorTemps_8[1]")
