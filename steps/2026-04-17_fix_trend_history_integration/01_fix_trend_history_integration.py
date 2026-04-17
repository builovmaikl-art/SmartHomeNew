from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

# 1. Добавим edge detection
edge_var = """
    // === TREND WRITE CONTROL ===
    L_Trend_Write : BOOL;
    L_Trend_Write_Prev : BOOL;
"""

if "TREND WRITE CONTROL" not in text:
    text = text.replace("VAR\n", "VAR\n" + edge_var, 1)

# 2. Исправим блок записи
old_block = "// === TREND → HISTORY WRITE ==="
new_block = """
// === TREND → HISTORY WRITE (EDGE) ===
L_Trend_Write := (L_Trend_Data.record_count > 0);

IF L_Trend_Write AND NOT L_Trend_Write_Prev THEN
    L_Trend_Event.event_code := 1001;
    L_Trend_Event.event_value := L_Trend_Data.average_value;
    L_Trend_Event.zone_id := 0;
    L_Trend_Event.operator_id := '';
END_IF;

L_Trend_Write_Prev := L_Trend_Write;
"""

if old_block in text:
    start = text.find(old_block)
    end = text.find("END_PROGRAM", start)
    text = text[:start] + new_block + text[end:]
else:
    text = text.replace("END_PROGRAM", new_block + "\nEND_PROGRAM")

path.write_text(text, encoding="utf-8")
print("OK: Trend history write fixed with edge detection")
