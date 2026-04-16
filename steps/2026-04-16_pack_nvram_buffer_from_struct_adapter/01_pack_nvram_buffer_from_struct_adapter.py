from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

replacements = {
    "L_Persist_Buffer[0] := TO_BYTE(TO_INT(GVL_STATE.G_System_Mode));":
    "L_Persist_Buffer[0] := TO_BYTE(TO_INT(L_Persist_Struct.System_Mode));",

    "IF GVL_PERSISTENT.P_Safety_Gas_Latched THEN":
    "IF L_Persist_Struct.Safety_Gas_Latched THEN",

    "IF GVL_PERSISTENT.P_Safety_Smoke_Latched THEN":
    "IF L_Persist_Struct.Safety_Smoke_Latched THEN",

    "IF GVL_PERSISTENT.P_Safety_Leak_Latched THEN":
    "IF L_Persist_Struct.Safety_Leak_Latched THEN",

    "IF GVL_PERSISTENT.P_DHW_Heating_Active THEN":
    "IF L_Persist_Struct.DHW_Heating_Pump THEN",
}

for old, new in replacements.items():
    if old not in text:
        raise SystemExit(f"Target text not found: {old}")
    text = text.replace(old, new, 1)

path.write_text(text, encoding="utf-8")
print("OK: L_Persist_Buffer now packs from L_Persist_Struct")
