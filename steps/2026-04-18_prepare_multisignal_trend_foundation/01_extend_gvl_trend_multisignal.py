from pathlib import Path

path = Path("GVL_Trend.gvl")
text = path.read_text(encoding="utf-8")

insert = """
    // === MULTI-SIGNAL TREND FOUNDATION ===
    G_Trend_Selected_Channel : BYTE := 1;
    G_Trend_Channel2_Enabled : BOOL := FALSE;
    G_Trend_Buffer_2 : ARRAY[1..50] OF REAL;
    G_Trend_Buffer_2_Timestamps : ARRAY[1..50] OF UDINT;
    G_Trend_Buffer_2_Index : INT;
    G_Trend_Buffer_2_Valid_Count : INT;
    G_Trend_Buffer_2_Is_Wrapped : BOOL;
    G_Trend_Channel2_Param_Type : BYTE := 0;
"""

if "G_Trend_Selected_Channel" not in text:
    text = text.replace("END_VAR", insert + "\nEND_VAR")

path.write_text(text, encoding="utf-8")
print("OK: added multi-signal trend foundation to GVL_Trend")
