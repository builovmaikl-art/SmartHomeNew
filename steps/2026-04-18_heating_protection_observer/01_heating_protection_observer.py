from pathlib import Path

# ------------------------------------------------------------
# 1) Extend diagnostics DUT
# ------------------------------------------------------------
dut = Path("ST_System_Diagnostics.dut")
dut_text = dut.read_text(encoding="utf-8")

anchor = "    Sensor_Shadow_Rate_Alert_Text : STRING(160);\n\n\n\nEND_STRUCT"
insert = """    Sensor_Shadow_Rate_Alert_Text : STRING(160);

    // === HEATING PROTECTION OBSERVER (ISOLATED) ===
    Heating_Freeze_Alert : BOOL;
    Heating_Freeze_Pump_Force_Request : BOOL;
    Heating_Overheat_Detected : BOOL;
    Heating_Overheat_Locked_Circuits : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF BOOL;
    Heating_Protection_Summary_Text : STRING(160);



END_STRUCT"""

if "Heating_Freeze_Alert : BOOL;" not in dut_text:
    if anchor not in dut_text:
        raise SystemExit("Diagnostics anchor not found in ST_System_Diagnostics.dut")
    dut_text = dut_text.replace(anchor, insert, 1)

dut.write_text(dut_text, encoding="utf-8")

# ------------------------------------------------------------
# 2) Add FB instances to PRG_System VAR
# ------------------------------------------------------------
prg = Path("PRG_System.st")
prg_text = prg.read_text(encoding="utf-8")

var_anchor = "fbSmokeDetector : FB_Smoke_Detector;"
var_insert = """fbSmokeDetector : FB_Smoke_Detector;
fbFreezeProtection : FB_FloorHeating_Freeze_Protection;
fbOverheatProtection : FB_FloorHeating_Overheat_Protection;"""

if "fbFreezeProtection : FB_FloorHeating_Freeze_Protection;" not in prg_text:
    if var_anchor not in prg_text:
        raise SystemExit("VAR anchor for heating protection FBs not found in PRG_System.st")
    prg_text = prg_text.replace(var_anchor, var_insert, 1)

# ------------------------------------------------------------
# 3) Insert observer block before snapshot layer
# ------------------------------------------------------------
marker = "// === SNAPSHOT LAYER (PHASE 1) ==="

block = """// === HEATING PROTECTION OBSERVER ===
fbFreezeProtection(
    VI_Outdoor_Temp := GVL_STATE.G_Outdoor_Temp,
    VI_Floor_Temps := L_FloorTemps_8
);

fbOverheatProtection(
    VI_Temps := L_FloorTemps_8
);

GVL_STATUS.G_Diagnostics.Heating_Freeze_Alert := fbFreezeProtection.VO_Freeze_Alert;
GVL_STATUS.G_Diagnostics.Heating_Freeze_Pump_Force_Request := fbFreezeProtection.VO_Pump_Force_On;
GVL_STATUS.G_Diagnostics.Heating_Overheat_Detected := fbOverheatProtection.VO_Overheat_Detected;
GVL_STATUS.G_Diagnostics.Heating_Overheat_Locked_Circuits := fbOverheatProtection.VO_Locked_Circuits;

IF GVL_STATUS.G_Diagnostics.Heating_Overheat_Detected THEN
    GVL_STATUS.G_Diagnostics.Heating_Protection_Summary_Text := 'Heating overheat detected';
ELSIF GVL_STATUS.G_Diagnostics.Heating_Freeze_Alert THEN
    GVL_STATUS.G_Diagnostics.Heating_Protection_Summary_Text := 'Heating freeze protection alert';
ELSIF GVL_STATUS.G_Diagnostics.Heating_Freeze_Pump_Force_Request THEN
    GVL_STATUS.G_Diagnostics.Heating_Protection_Summary_Text := 'Heating anti-freeze pump request';
ELSE
    GVL_STATUS.G_Diagnostics.Heating_Protection_Summary_Text := 'Heating protection normal';
END_IF;

"""

if "// === HEATING PROTECTION OBSERVER ===" not in prg_text:
    if marker not in prg_text:
        raise SystemExit("Snapshot marker not found in PRG_System.st")
    prg_text = prg_text.replace(marker, block + marker, 1)

prg.write_text(prg_text, encoding="utf-8")
print("OK: heating protection observer integrated")
