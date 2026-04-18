from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

block = """
// === TREND META UPDATE ===
GVL_Trend.G_Trend_Last_Update_MS := GVL_STATUS.G_System_Time_MS;
GVL_Trend.G_Trend_Param_Type := 1; // TEMP_AIR (пока фикс)

IF GVL_Trend.G_Trend_Valid_Count < 50 THEN
    GVL_Trend.G_Trend_Valid_Count := GVL_Trend.G_Trend_Valid_Count + 1;
ELSE
    GVL_Trend.G_Trend_Is_Wrapped := TRUE;
END_IF;
"""

if "// === TREND META UPDATE ===" not in text:
    text = text.replace(
        "// === TREND BUFFER UPDATE ===",
        "// === TREND BUFFER UPDATE ===\n" + block
    )

path.write_text(text, encoding="utf-8")
print("OK: added trend meta logic")
