from pathlib import Path

# ------------------------------------------------------------
# 1) Extend diagnostics
# ------------------------------------------------------------
dut = Path("ST_System_Diagnostics.dut")
dut_text = dut.read_text(encoding="utf-8")

anchor = "    Heating_Last_Event_Text : STRING(160);\n\n\n\nEND_STRUCT"
insert = """    Heating_Last_Event_Text : STRING(160);

    // === HEATING PRIORITY ARBITRATION ===
    Heating_Pump_Force_Allowed : BOOL;
    Heating_Zone_Lock_Allowed : BOOL;
    Heating_Arbitration_Text : STRING(160);



END_STRUCT"""

if "Heating_Pump_Force_Allowed : BOOL;" not in dut_text:
    if anchor not in dut_text:
        raise SystemExit("Diagnostics anchor not found in ST_System_Diagnostics.dut")
    dut_text = dut_text.replace(anchor, insert, 1)

dut.write_text(dut_text, encoding="utf-8")

# ------------------------------------------------------------
# 2) Insert arbitration block before real enforcement bridge
# ------------------------------------------------------------
prg = Path("PRG_System.st")
prg_text = prg.read_text(encoding="utf-8")

anchor = "// === HEATING REAL ENFORCEMENT BRIDGE ==="

block = """// === HEATING PRIORITY ARBITRATION ===
// Safe policy:
// - pump force is blocked in SAFE_STOP and on emergency stop
// - overheated circuit lock remains allowed as a protective restriction
GVL_STATUS.G_Diagnostics.Heating_Pump_Force_Allowed :=
    (GVL_STATE.G_System_Mode <> E_System_Operating_Mode.MODE_SAFE_STOP) AND
    (NOT GVL_STATE.G_Safety_Emergency_Stop);

GVL_STATUS.G_Diagnostics.Heating_Zone_Lock_Allowed := TRUE;

IF NOT GVL_STATUS.G_Diagnostics.Heating_Pump_Force_Allowed THEN
    GVL_STATUS.G_Diagnostics.Heating_Arbitration_Text := 'Pump force blocked by mode/safety';
ELSIF NOT GVL_STATUS.G_Diagnostics.Heating_Zone_Lock_Allowed THEN
    GVL_STATUS.G_Diagnostics.Heating_Arbitration_Text := 'Zone lock blocked by arbitration';
ELSE
    GVL_STATUS.G_Diagnostics.Heating_Arbitration_Text := 'Heating arbitration allows enforcement';
END_IF;

"""

if "// === HEATING PRIORITY ARBITRATION ===" not in prg_text:
    if anchor not in prg_text:
        raise SystemExit("Real enforcement bridge anchor not found in PRG_System.st")
    prg_text = prg_text.replace(anchor, block + anchor, 1)

# ------------------------------------------------------------
# 3) Gate the real enforcement bridge
# ------------------------------------------------------------
old = """// real bridge: force manifold pumps if freeze protection requests pump support
IF GVL_STATUS.G_Diagnostics.Heating_Pump_Force_Request_Active THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
        IF GVL_CONFIG.G_Manifold_Pump_In_Service[L_i] THEN
            GVL_STATE.G_Manifold_Pumps[L_i] := TRUE;
            GVL_STATUS.G_Diagnostics.Heating_Pump_Force_Bridge_Active := TRUE;
        END_IF;
    END_FOR;
END_IF;

// real bridge: close overheated floor-heating circuits
IF GVL_STATUS.G_Diagnostics.Heating_Overheat_Enforcement_Request_Active THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
        IF GVL_STATUS.G_Diagnostics.Heating_Overheat_Locked_Circuits[L_i] THEN
            GVL_STATE.G_Zone_Valves[L_i] := FALSE;
            GVL_STATUS.G_Diagnostics.Heating_Zone_Lock_Bridge_Active := TRUE;
        END_IF;
    END_FOR;
END_IF;
"""

new = """// real bridge: force manifold pumps if freeze protection requests pump support
IF GVL_STATUS.G_Diagnostics.Heating_Pump_Force_Request_Active AND
   GVL_STATUS.G_Diagnostics.Heating_Pump_Force_Allowed THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
        IF GVL_CONFIG.G_Manifold_Pump_In_Service[L_i] THEN
            GVL_STATE.G_Manifold_Pumps[L_i] := TRUE;
            GVL_STATUS.G_Diagnostics.Heating_Pump_Force_Bridge_Active := TRUE;
        END_IF;
    END_FOR;
END_IF;

// real bridge: close overheated floor-heating circuits
IF GVL_STATUS.G_Diagnostics.Heating_Overheat_Enforcement_Request_Active AND
   GVL_STATUS.G_Diagnostics.Heating_Zone_Lock_Allowed THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
        IF GVL_STATUS.G_Diagnostics.Heating_Overheat_Locked_Circuits[L_i] THEN
            GVL_STATE.G_Zone_Valves[L_i] := FALSE;
            GVL_STATUS.G_Diagnostics.Heating_Zone_Lock_Bridge_Active := TRUE;
        END_IF;
    END_FOR;
END_IF;
"""

if old not in prg_text:
    raise SystemExit("Expected real enforcement bridge body not found exactly")

prg_text = prg_text.replace(old, new, 1)
prg.write_text(prg_text, encoding="utf-8")
print("OK: heating priority arbitration integrated")
