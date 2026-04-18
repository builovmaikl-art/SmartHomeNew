from pathlib import Path

# ------------------------------------------------------------
# 1) Extend diagnostics with real bridge state
# ------------------------------------------------------------
dut = Path("ST_System_Diagnostics.dut")
dut_text = dut.read_text(encoding="utf-8")

anchor = "    Heating_Enforcement_Request_Text : STRING(160);\n\n\n\nEND_STRUCT"
insert = """    Heating_Enforcement_Request_Text : STRING(160);

    // === HEATING REAL ENFORCEMENT BRIDGE (ISOLATED) ===
    Heating_Pump_Force_Bridge_Active : BOOL;
    Heating_Zone_Lock_Bridge_Active : BOOL;
    Heating_Real_Enforcement_Text : STRING(160);



END_STRUCT"""

if "Heating_Pump_Force_Bridge_Active : BOOL;" not in dut_text:
    if anchor not in dut_text:
        raise SystemExit("Diagnostics anchor not found in ST_System_Diagnostics.dut")
    dut_text = dut_text.replace(anchor, insert, 1)

dut.write_text(dut_text, encoding="utf-8")

# ------------------------------------------------------------
# 2) Insert real enforcement bridge after request layer
# ------------------------------------------------------------
prg = Path("PRG_System.st")
prg_text = prg.read_text(encoding="utf-8")

request_tail = """ELSE
    GVL_STATUS.G_Diagnostics.Heating_Enforcement_Request_Text := 'No heating enforcement requests';
END_IF;

"""

bridge_block = """// === HEATING REAL ENFORCEMENT BRIDGE ===
GVL_STATUS.G_Diagnostics.Heating_Pump_Force_Bridge_Active := FALSE;
GVL_STATUS.G_Diagnostics.Heating_Zone_Lock_Bridge_Active := FALSE;

// real bridge: force manifold pumps if freeze protection requests pump support
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

IF GVL_STATUS.G_Diagnostics.Heating_Zone_Lock_Bridge_Active THEN
    GVL_STATUS.G_Diagnostics.Heating_Real_Enforcement_Text := 'Applied: overheated circuits locked';
ELSIF GVL_STATUS.G_Diagnostics.Heating_Pump_Force_Bridge_Active THEN
    GVL_STATUS.G_Diagnostics.Heating_Real_Enforcement_Text := 'Applied: heating pumps forced on';
ELSE
    GVL_STATUS.G_Diagnostics.Heating_Real_Enforcement_Text := 'No real heating enforcement applied';
END_IF;

"""

if "// === HEATING REAL ENFORCEMENT BRIDGE ===" not in prg_text:
    if request_tail not in prg_text:
        raise SystemExit("Request layer tail anchor not found in PRG_System.st")
    prg_text = prg_text.replace(request_tail, request_tail + bridge_block, 1)

prg.write_text(prg_text, encoding="utf-8")
print("OK: heating real enforcement bridge integrated")
