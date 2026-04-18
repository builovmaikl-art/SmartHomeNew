from pathlib import Path

path = Path("GVL_Trend.gvl")
text = path.read_text(encoding="utf-8")

insert = """
    // === TREND META FOR HMI ===
    G_Trend_Valid_Count : INT;
    G_Trend_Is_Wrapped : BOOL;
    G_Trend_Last_Update_MS : UDINT;
    G_Trend_Param_Type : BYTE;
"""

if "G_Trend_Valid_Count" not in text:
    text = text.replace("END_VAR", insert + "\nEND_VAR")

path.write_text(text, encoding="utf-8")
print("OK: added trend meta to GVL_Trend")
