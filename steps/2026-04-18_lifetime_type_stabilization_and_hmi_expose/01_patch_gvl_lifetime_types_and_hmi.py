from pathlib import Path

path = Path("GVL_Lifetime.gvl")
text = path.read_text(encoding="utf-8")

text = text.replace(
    "    G_Pump_Nominal_Hours : REAL := 10000.0;",
    "    G_Pump_Nominal_Hours : UDINT := 10000;"
)
text = text.replace(
    "    G_Fan_Nominal_Hours  : REAL := 15000.0;",
    "    G_Fan_Nominal_Hours  : UDINT := 15000;"
)
text = text.replace(
    "    G_Maintenance_Threshold_Percent : REAL := 20.0;",
    "    G_Maintenance_Threshold_Percent : BYTE := 20;"
)

insert = """
    // === HMI ACTIVE VIEW ===
    G_Active_Device_Index : INT := 1;
    G_Active_Runtime_Hours : UDINT;
    G_Active_Remaining_Hours : UDINT;
    G_Active_Remaining_Percent : BYTE;
    G_Active_Maintenance_Required : BOOL;

    // === HMI LABELS ===
    G_Device1_Label : STRING(32) := 'Pump';
    G_Device2_Label : STRING(32) := 'Vent Fan';
    G_Active_Label : STRING(32);
"""

if "G_Active_Device_Index" not in text:
    text = text.replace("END_VAR", insert + "\nEND_VAR")

path.write_text(text, encoding="utf-8")
print("OK: stabilized GVL_Lifetime scalar types and added HMI active-view fields")
