from pathlib import Path

path = Path("GVL_Lifetime.gvl")
text = path.read_text(encoding="utf-8")

text = text.replace(
    "    G_Status : ARRAY[1..2] OF ST_Lifetime_Status;",
    "    G_Status : ARRAY[1..4] OF ST_Lifetime_Status;"
)

insert = """
    // === RESERVED DEVICE IDS ===
    G_Device_Reserved_3 : BYTE := 3;
    G_Device_Reserved_4 : BYTE := 4;

    // === HMI LABEL ARRAY ===
    G_Device_Labels : ARRAY[1..4] OF STRING(32) := ['Pump', 'Vent Fan', 'Reserved 3', 'Reserved 4'];

    // === HEALTH SUMMARY ===
    G_Any_Maintenance_Required : BOOL;
    G_Maintenance_Warning : BOOL;
    G_Maintenance_Critical : BOOL;
"""

if "G_Device_Reserved_3" not in text:
    text = text.replace("END_VAR", insert + "\nEND_VAR")

path.write_text(text, encoding="utf-8")
print("OK: patched GVL_Lifetime scaling + health summary fields")
