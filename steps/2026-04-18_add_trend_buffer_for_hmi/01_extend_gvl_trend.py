from pathlib import Path

path = Path("GVL_Trend.gvl")
text = path.read_text(encoding="utf-8")

insert = """
    // === TREND BUFFER FOR HMI ===
    G_Trend_Buffer : ARRAY[1..50] OF REAL;
    G_Trend_Buffer_Index : INT;
"""

if "G_Trend_Buffer" not in text:
    text = text.replace("END_VAR", insert + "\nEND_VAR")

path.write_text(text, encoding="utf-8")
print("OK: extended GVL_Trend with buffer")
