from pathlib import Path

# ------------------------------------------------------------
# 1) Extend diagnostics
# ------------------------------------------------------------
dut = Path("ST_System_Diagnostics.dut")
dut_text = dut.read_text(encoding="utf-8")

anchor = "    Heating_Real_Enforcement_Text : STRING(160);\n\n\n\nEND_STRUCT"
insert = """    Heating_Real_Enforcement_Text : STRING(160);

    // === HEATING ENFORCEMENT TELEMETRY ===
    Heating_Pump_Force_Event_Count : UDINT;
    Heating_Zone_Lock_Event_Count : UDINT;
    Heating_Last_Event_Time_MS : UDINT;
    Heating_Last_Event_Text : STRING(160);



END_STRUCT"""

if "Heating_Pump_Force_Event_Count : UDINT;" not in dut_text:
    if anchor not in dut_text:
        raise SystemExit("Diagnostics anchor not found in ST_System_Diagnostics.dut")
    dut_text = dut_text.replace(anchor, insert, 1)

dut.write_text(dut_text, encoding="utf-8")

# ------------------------------------------------------------
# 2) Add prev-state vars
# ------------------------------------------------------------
prg = Path("PRG_System.st")
prg_text = prg.read_text(encoding="utf-8")

var_anchor = "L_Snapshot_Recovery_Prev : BOOL;"
var_insert = """L_Snapshot_Recovery_Prev : BOOL;
L_Heating_Pump_Force_Bridge_Prev : BOOL;
L_Heating_Zone_Lock_Bridge_Prev : BOOL;"""

if "L_Heating_Pump_Force_Bridge_Prev : BOOL;" not in prg_text:
    if var_anchor not in prg_text:
        raise SystemExit("VAR anchor not found in PRG_System.st")
    prg_text = prg_text.replace(var_anchor, var_insert, 1)

# ------------------------------------------------------------
# 3) Insert telemetry after real enforcement bridge
# ------------------------------------------------------------
tail = """ELSE
    GVL_STATUS.G_Diagnostics.Heating_Real_Enforcement_Text := 'No real heating enforcement applied';
END_IF;

"""

block = """// === HEATING ENFORCEMENT TELEMETRY ===
IF GVL_STATUS.G_Diagnostics.Heating_Pump_Force_Bridge_Active AND
   (NOT L_Heating_Pump_Force_Bridge_Prev) THEN
    GVL_STATUS.G_Diagnostics.Heating_Pump_Force_Event_Count :=
        GVL_STATUS.G_Diagnostics.Heating_Pump_Force_Event_Count + 1;
    GVL_STATUS.G_Diagnostics.Heating_Last_Event_Time_MS := GVL_STATUS.G_System_Time_MS;
    GVL_STATUS.G_Diagnostics.Heating_Last_Event_Text := 'Pump force bridge activated';
END_IF;

IF GVL_STATUS.G_Diagnostics.Heating_Zone_Lock_Bridge_Active AND
   (NOT L_Heating_Zone_Lock_Bridge_Prev) THEN
    GVL_STATUS.G_Diagnostics.Heating_Zone_Lock_Event_Count :=
        GVL_STATUS.G_Diagnostics.Heating_Zone_Lock_Event_Count + 1;
    GVL_STATUS.G_Diagnostics.Heating_Last_Event_Time_MS := GVL_STATUS.G_System_Time_MS;
    GVL_STATUS.G_Diagnostics.Heating_Last_Event_Text := 'Zone lock bridge activated';
END_IF;

L_Heating_Pump_Force_Bridge_Prev := GVL_STATUS.G_Diagnostics.Heating_Pump_Force_Bridge_Active;
L_Heating_Zone_Lock_Bridge_Prev := GVL_STATUS.G_Diagnostics.Heating_Zone_Lock_Bridge_Active;

"""

if "// === HEATING ENFORCEMENT TELEMETRY ===" not in prg_text:
    if tail not in prg_text:
        raise SystemExit("Real enforcement tail anchor not found in PRG_System.st")
    prg_text = prg_text.replace(tail, tail + block, 1)

prg.write_text(prg_text, encoding="utf-8")
print("OK: heating enforcement telemetry integrated")
