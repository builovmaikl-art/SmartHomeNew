from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

# 1. Добавляем FB и переменные
var_anchor = "L_Trend_Data : ST_Trend_Data;\n"
insert_vars = """    L_Trend_Adapter : FB_Trend_Adapter;
    L_Trend_Avg : REAL;
    L_Trend_Min : REAL;
    L_Trend_Max : REAL;
    L_Trend_Up : BOOL;
    L_Trend_Down : BOOL;
"""

if var_anchor not in text:
    raise SystemExit("Trend data anchor not found")

if "L_Trend_Adapter" not in text:
    text = text.replace(var_anchor, var_anchor + insert_vars, 1)

# 2. Вставляем вызов адаптера после логгера
adapter_call = """
// === TREND ANALYSIS VIA ADAPTER ===
L_Trend_Adapter(
    VI_Data := L_Trend_Data,
    VO_Average => L_Trend_Avg,
    VO_Min => L_Trend_Min,
    VO_Max => L_Trend_Max,
    VO_Trend_Up => L_Trend_Up,
    VO_Trend_Down => L_Trend_Down
);
"""

if "// === TREND ANALYSIS VIA ADAPTER ===" not in text:
    text = text.replace(
        "L_Trend_Data := L_Trend_Logger.VO_Data;",
        "L_Trend_Data := L_Trend_Logger.VO_Data;\n" + adapter_call
    )

# 3. Обновляем запись в history (только average пока)
old = "L_Trend_Event.event_value := L_Trend_Data.sum_values / UDINT_TO_REAL(L_Trend_Data.record_count);"
new = "L_Trend_Event.event_value := L_Trend_Avg;"

if old in text:
    text = text.replace(old, new)

path.write_text(text, encoding="utf-8")
print("OK: integrated trend adapter into PRG_System")
