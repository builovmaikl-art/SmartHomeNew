from pathlib import Path

path = Path("GVL_Trend.gvl")
text = path.read_text(encoding="utf-8")

insert = """
    // === ACTIVE TREND VIEW FOR HMI ===
    G_Trend_Active_Value : REAL;
    G_Trend_Active_Timestamp : UDINT;
    G_Trend_Active_Index : INT;
    G_Trend_Active_Valid_Count : INT;
    G_Trend_Active_Is_Wrapped : BOOL;
"""

if "G_Trend_Active_Value" not in text:
    text = text.replace("END_VAR", insert + "\nEND_VAR")

path.write_text(text, encoding="utf-8")
print("OK: added active trend view fields to GVL_Trend")
