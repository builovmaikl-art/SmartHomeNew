from pathlib import Path

path = Path("GVL_Trend.gvl")
text = path.read_text(encoding="utf-8")

insert = """
    G_Trend_Buffer_Timestamps : ARRAY[1..50] OF UDINT;
"""

if "G_Trend_Buffer_Timestamps" not in text:
    anchor = "    G_Trend_Buffer_Index : INT;\n"
    if anchor not in text:
        raise SystemExit("GVL_Trend buffer anchor not found")
    text = text.replace(anchor, anchor + insert, 1)

path.write_text(text, encoding="utf-8")
print("OK: added G_Trend_Buffer_Timestamps to GVL_Trend")
