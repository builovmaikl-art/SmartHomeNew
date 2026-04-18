from pathlib import Path

# ------------------------------------------------------------
# 1) Extend diagnostics
# ------------------------------------------------------------
dut = Path("ST_System_Diagnostics.dut")
dut_text = dut.read_text(encoding="utf-8")

anchor = "    Heating_Arbitration_Text : STRING(160);\n\n\n\nEND_STRUCT"
insert = """    Heating_Arbitration_Text : STRING(160);

    // === HEATING ENFORCEMENT COOLDOWN ===
    Heating_Pump_Force_Hold_Active : BOOL;
    Heating_Zone_Lock_Hold_Active : BOOL;
    Heating_Pump_Force_Hold_Until_MS : UDINT;
    Heating_Zone_Lock_Hold_Until_MS : UDINT;
    Heating_Cooldown_Text : STRING(160);



END_STRUCT"""

if "Heating_Pump_Force_Hold_Active : BOOL;" not in dut_text:
    if anchor not in dut_text:
        raise SystemExit("Diagnostics anchor not found in ST_System_Diagnostics.dut")
    dut_text = dut_text.replace(anchor, insert, 1)

dut.write_text(dut_text, encoding="utf-8")

# ------------------------------------------------------------
# 2) Add VARs
# ------------------------------------------------------------
prg = Path("PRG_System.st")
prg_text = prg.read_text(encoding="utf-8")

var_anchor = "L_Heating_Zone_Lock_Bridge_Prev : BOOL;"
var_insert = """L_Heating_Zone_Lock_Bridge_Prev : BOOL;
L_Heating_Pump_Force_Hold_MS : UDINT;
L_Heating_Zone_Lock_Hold_MS : UDINT;"""

if "L_Heating_Pump_Force_Hold_MS : UDINT;" not in prg_text:
    if var_anchor not in prg_text:
        raise SystemExit("VAR anchor not found in PRG_System.st")
    prg_text = prg_text.replace(var_anchor, var_insert, 1)

# ------------------------------------------------------------
# 3) Insert cooldown block before real enforcement bridge
# ------------------------------------------------------------
anchor = "// === HEATING REAL ENFORCEMENT BRIDGE ==="

cooldown_block = """// === HEATING ENFORCEMENT COOLDOWN ===
IF L_Heating_Pump_Force_Hold_MS = 0 THEN
    L_Heating_Pump_Force_Hold_MS := 30000;
END_IF;

IF L_Heating_Zone_Lock_Hold_MS = 0 THEN
    L_Heating_Zone_Lock_Hold_MS := 60000;
END_IF;

// start/refresh holds from active requests
IF GVL_STATUS.G_Diagnostics.Heating_Pump_Force_Request_Active THEN
    GVL_STATUS.G_Diagnostics.Heating_Pump_Force_Hold_Until_MS :=
        GVL_STATUS.G_System_Time_MS + L_Heating_Pump_Force_Hold_MS;
END_IF;

IF GVL_STATUS.G_Diagnostics.Heating_Overheat_Enforcement_Request_Active THEN
    GVL_STATUS.G_Diagnostics.Heating_Zone_Lock_Hold_Until_MS :=
        GVL_STATUS.G_System_Time_MS + L_Heating_Zone_Lock_Hold_MS;
END_IF;

GVL_STATUS.G_Diagnostics.Heating_Pump_Force_Hold_Active :=
    (GVL_STATUS.G_Diagnostics.Heating_Pump_Force_Hold_Until_MS > 0) AND
    (GVL_STATUS.G_System_Time_MS < GVL_STATUS.G_Diagnostics.Heating_Pump_Force_Hold_Until_MS);

GVL_STATUS.G_Diagnostics.Heating_Zone_Lock_Hold_Active :=
    (GVL_STATUS.G_Diagnostics.Heating_Zone_Lock_Hold_Until_MS > 0) AND
    (GVL_STATUS.G_System_Time_MS < GVL_STATUS.G_Diagnostics.Heating_Zone_Lock_Hold_Until_MS);

IF GVL_STATUS.G_Diagnostics.Heating_Zone_Lock_Hold_Active THEN
    GVL_STATUS.G_Diagnostics.Heating_Cooldown_Text := 'Zone lock hold active';
ELSIF GVL_STATUS.G_Diagnostics.Heating_Pump_Force_Hold_Active THEN
    GVL_STATUS.G_Diagnostics.Heating_Cooldown_Text := 'Pump force hold active';
ELSE
    GVL_STATUS.G_Diagnostics.Heating_Cooldown_Text := 'No heating cooldown hold active';
END_IF;

"""

if "// === HEATING ENFORCEMENT COOLDOWN ===" not in prg_text:
    if anchor not in prg_text:
        raise SystemExit("Real enforcement bridge anchor not found in PRG_System.st")
    prg_text = prg_text.replace(anchor, cooldown_block + anchor, 1)

# ------------------------------------------------------------
# 4) Gate real enforcement by request OR hold
# ------------------------------------------------------------
old = """// real bridge: force manifold pumps if freeze protection requests pump support
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

new = """// real bridge: force manifold pumps if freeze protection requests pump support
IF (GVL_STATUS.G_Diagnostics.Heating_Pump_Force_Request_Active OR
    GVL_STATUS.G_Diagnostics.Heating_Pump_Force_Hold_Active) AND
   GVL_STATUS.G_Diagnostics.Heating_Pump_Force_Allowed THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
        IF GVL_CONFIG.G_Manifold_Pump_In_Service[L_i] THEN
            GVL_STATE.G_Manifold_Pumps[L_i] := TRUE;
            GVL_STATUS.G_Diagnostics.Heating_Pump_Force_Bridge_Active := TRUE;
        END_IF;
    END_FOR;
END_IF;

// real bridge: close overheated floor-heating circuits
IF (GVL_STATUS.G_Diagnostics.Heating_Overheat_Enforcement_Request_Active OR
    GVL_STATUS.G_Diagnostics.Heating_Zone_Lock_Hold_Active) AND
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
print("OK: heating enforcement cooldown integrated")
