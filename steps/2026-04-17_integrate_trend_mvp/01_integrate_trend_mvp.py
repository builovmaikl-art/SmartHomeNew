from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

# 1. Добавляем VAR если нет
if "FB_Trend_Logger" not in text:
    insert_var = """
    // === TREND SYSTEM (MVP) ===
    L_Trend_Logger : FB_Trend_Logger;
    L_Trend_Analyzer : FB_Trend_Analyzer;
    L_Trend_Data : ST_Trend_Data;
"""
    text = text.replace("VAR\n", "VAR\n" + insert_var, 1)

# 2. Добавляем вызов (в конец перед END_PROGRAM или последним END_IF)
call_block = """
// === TREND EXECUTION (MVP) ===
L_Trend_Logger(
    VI_Current_Value := REAL(GVL_SENSORS.G_Outdoor_Temperature),
    VI_Config.enabled := TRUE,
    VI_Config.history_days := 1,
    VI_Config.deviation_threshold_percent := 1.0,
    VO_Data => L_Trend_Data
);

L_Trend_Analyzer(
    VI_Data := L_Trend_Data,
    VO_Average => ,
    VO_Min => ,
    VO_Max => ,
    VO_Trend_Up => ,
    VO_Trend_Down => 
);
"""

if "// === TREND EXECUTION (MVP) ===" not in text:
    text = text.replace("END_PROGRAM", call_block + "\nEND_PROGRAM")

path.write_text(text, encoding="utf-8")
print("OK: Trend MVP integrated into PRG_System")
