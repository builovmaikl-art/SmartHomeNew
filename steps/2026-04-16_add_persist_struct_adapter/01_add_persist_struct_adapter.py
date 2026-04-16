from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

# 1. Добавляем переменную структуры
var_block = "VAR\n"
insert_struct = "    L_Persist_Struct : ST_Persist;\n"

if insert_struct not in text:
    text = text.replace(var_block, var_block + insert_struct, 1)

# 2. Заменяем snapshot блок
old_block = """// --- Snapshot state to persistent storage ---
GVL_PERSISTENT.P_System_Mode := GVL_STATE.G_System_Mode;

GVL_PERSISTENT.P_Safety_Gas_Latched := GVL_STATE.G_Safety_Gas_Latched;
GVL_PERSISTENT.P_Safety_Smoke_Latched := GVL_STATE.G_Safety_Smoke_Latched;
GVL_PERSISTENT.P_Safety_Leak_Latched := GVL_STATE.G_Safety_Leak_Latched;

GVL_PERSISTENT.P_DHW_Heating_Active := GVL_STATE.G_DHW_Heating_Pump;
GVL_PERSISTENT.P_Valid := TRUE;
"""

new_block = """// --- Snapshot state to persistent struct ---
L_Persist_Struct.System_Mode := GVL_STATE.G_System_Mode;

L_Persist_Struct.Safety_Gas_Latched := GVL_STATE.G_Safety_Gas_Latched;
L_Persist_Struct.Safety_Smoke_Latched := GVL_STATE.G_Safety_Smoke_Latched;
L_Persist_Struct.Safety_Leak_Latched := GVL_STATE.G_Safety_Leak_Latched;

L_Persist_Struct.DHW_Heating_Pump := GVL_STATE.G_DHW_Heating_Pump;
L_Persist_Struct.Valid := TRUE;

// --- Mirror to legacy persistent ---
GVL_PERSISTENT.P_System_Mode := L_Persist_Struct.System_Mode;

GVL_PERSISTENT.P_Safety_Gas_Latched := L_Persist_Struct.Safety_Gas_Latched;
GVL_PERSISTENT.P_Safety_Smoke_Latched := L_Persist_Struct.Safety_Smoke_Latched;
GVL_PERSISTENT.P_Safety_Leak_Latched := L_Persist_Struct.Safety_Leak_Latched;

GVL_PERSISTENT.P_DHW_Heating_Active := L_Persist_Struct.DHW_Heating_Pump;
GVL_PERSISTENT.P_Valid := L_Persist_Struct.Valid;
"""

if old_block not in text:
    raise SystemExit("Snapshot block not found in PRG_System.st")

text = text.replace(old_block, new_block, 1)

path.write_text(text, encoding="utf-8")
print("OK: persist struct adapter added")
