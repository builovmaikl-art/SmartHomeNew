from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

# Добавим структуру события
insert_var = """
    // === TREND → HISTORY BRIDGE ===
    L_Trend_Event : ST_History_Record;
    L_Trend_Write : BOOL;
"""

if "TREND → HISTORY BRIDGE" not in text:
    text = text.replace("VAR\n", "VAR\n" + insert_var, 1)

# Добавим логику записи
bridge_code = """
// === TREND → HISTORY WRITE ===
L_Trend_Write := TRUE;

IF L_Trend_Write THEN
    L_Trend_Event.event_code := 1001; // Trend average
    L_Trend_Event.event_value := L_Trend_Data.average_value;
    L_Trend_Event.zone_id := 0;
    L_Trend_Event.operator_id := '';
END_IF;
"""

if "// === TREND → HISTORY WRITE ===" not in text:
    text = text.replace("END_PROGRAM", bridge_code + "\nEND_PROGRAM")

path.write_text(text, encoding="utf-8")
print("OK: Trend → History bridge added")
