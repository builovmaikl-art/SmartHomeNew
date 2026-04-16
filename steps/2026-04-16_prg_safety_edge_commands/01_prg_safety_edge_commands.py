from pathlib import Path

path = Path("PRG_Safety.st")
text = path.read_text(encoding="utf-8")

commands = [
    "CMD_Water_Selective_Recover",
    "CMD_Gas_Selective_Recover",
    "CMD_Water_Valve_Test_Open",
    "CMD_Water_Valve_Test_Close",
    "CMD_Water_Valve_Test_Confirm",
    "CMD_Gas_Valve_Test_Open",
    "CMD_Gas_Valve_Test_Close",
    "CMD_Gas_Valve_Test_Confirm",
]

# 1. Добавляем VAR
var_anchor = "VAR\n"
var_block = ""

for cmd in commands:
    var_block += f"    L_{cmd}_Prev : BOOL;\n"
    var_block += f"    L_{cmd}_Edge : BOOL;\n"

if "L_CMD_Water_Selective_Recover_Prev" not in text:
    if var_anchor not in text:
        raise SystemExit("VAR block not found")
    text = text.replace(var_anchor, var_anchor + var_block, 1)

# 2. Добавляем edge вычисление (в начало логики)
edge_block = "\n// === COMMAND EDGE PROCESSING ===\n"

for cmd in commands:
    edge_block += f"L_{cmd}_Edge := GVL_COMMAND.{cmd} AND NOT L_{cmd}_Prev;\n"

edge_block += "\n"

for cmd in commands:
    edge_block += f"L_{cmd}_Prev := GVL_COMMAND.{cmd};\n"

if "// === COMMAND EDGE PROCESSING ===" not in text:
    # вставим после VAR блока
    insert_point = text.find("END_VAR")
    if insert_point == -1:
        raise SystemExit("END_VAR not found")
    insert_point = text.find("\n", insert_point) + 1
    text = text[:insert_point] + edge_block + text[insert_point:]

# 3. Заменяем IF CMD → IF EDGE
for cmd in commands:
    text = text.replace(
        f"IF GVL_COMMAND.{cmd}",
        f"IF L_{cmd}_Edge"
    )

path.write_text(text, encoding="utf-8")
print("OK: PRG_Safety commands converted to edge-triggered")
