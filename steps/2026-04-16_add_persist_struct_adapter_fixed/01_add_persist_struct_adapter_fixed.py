from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

var_anchor = "    L_Recovery_Done : BOOL;\nEND_VAR\n"
var_insert = "    L_Persist_Struct : ST_Persist;\n"

if var_insert not in text:
    if var_anchor not in text:
        raise SystemExit("VAR anchor not found in PRG_System.st")
    text = text.replace(var_anchor, "    L_Recovery_Done : BOOL;\n" + var_insert + "END_VAR\n", 1)

old_block = """// === NVRAM SNAPSHOT (NO WRITE YET) ===
GVL_PERSISTENT.P_System_Mode := GVL_STATE.G_System_Mode;

GVL_PERSISTENT.P_Safety_Gas_Latched := GVL_STATE.G_Safety_Gas_Latched;
GVL_PERSISTENT.P_Safety_Smoke_Latched := GVL_STATE.G_Safety_Smoke_Latched;
GVL_PERSISTENT.P_Safety_Leak_Latched := GVL_STATE.G_Safety_Leak_Latched;

GVL_PERSISTENT.P_DHW_Heating_Active := GVL_STATE.G_DHW_Heating_Pump;

GVL_PERSISTENT.P_Valid := TRUE;
"""

new_block = """// === NVRAM SNAPSHOT VIA STRUCT ADAPTER ===
L_Persist_Struct.System_Mode := GVL_STATE.G_System_Mode;

L_Persist_Struct.Safety_Gas_Latched := GVL_STATE.G_Safety_Gas_Latched;
L_Persist_Struct.Safety_Smoke_Latched := GVL_STATE.G_Safety_Smoke_Latched;
L_Persist_Struct.Safety_Leak_Latched := GVL_STATE.G_Safety_Leak_Latched;

L_Persist_Struct.DHW_Heating_Pump := GVL_STATE.G_DHW_Heating_Pump;
L_Persist_Struct.Valid := TRUE;

// mirror to legacy persistent variables
GVL_PERSISTENT.P_System_Mode := L_Persist_Struct.System_Mode;

GVL_PERSISTENT.P_Safety_Gas_Latched := L_Persist_Struct.Safety_Gas_Latched;
GVL_PERSISTENT.P_Safety_Smoke_Latched := L_Persist_Struct.Safety_Smoke_Latched;
GVL_PERSISTENT.P_Safety_Leak_Latched := L_Persist_Struct.Safety_Leak_Latched;

GVL_PERSISTENT.P_DHW_Heating_Active := L_Persist_Struct.DHW_Heating_Pump;
GVL_PERSISTENT.P_Valid := L_Persist_Struct.Valid;
"""

if old_block not in text:
    raise SystemExit("Live snapshot block not found in PRG_System.st")

text = text.replace(old_block, new_block, 1)

path.write_text(text, encoding="utf-8")
print("OK: persist struct adapter added to PRG_System.st")
