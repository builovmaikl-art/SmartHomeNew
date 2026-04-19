from pathlib import Path

# ------------------------------------------------------------
# 1) Extend diagnostics
# ------------------------------------------------------------
dut = Path("ST_System_Diagnostics.dut")
dut_text = dut.read_text(encoding="utf-8")

anchor = "    Calibration_Last_Event_Text : STRING(160);\n\n\n\nEND_STRUCT"
insert = """    Calibration_Last_Event_Text : STRING(160);

    // === FLOOR TEMP CALIBRATION OBSERVER (PILOT) ===
    Calibration_FloorTemp1_Active : BOOL;
    Calibration_FloorTemp1_Verification_Active : BOOL;
    Calibration_FloorTemp1_Verification_Failed : BOOL;
    Calibration_FloorTemp1_Deviation_Percent : REAL;
    Calibration_FloorTemp1_Summary_Text : STRING(160);



END_STRUCT"""

if "Calibration_FloorTemp1_Active : BOOL;" not in dut_text:
    if anchor not in dut_text:
        raise SystemExit("Diagnostics anchor not found in ST_System_Diagnostics.dut")
    dut_text = dut_text.replace(anchor, insert, 1)

dut.write_text(dut_text, encoding="utf-8")

# ------------------------------------------------------------
# 2) Extend PRG_System VAR
# ------------------------------------------------------------
prg = Path("PRG_System.st")
prg_text = prg.read_text(encoding="utf-8")

fb_anchor = "fbCalibVerifyMethane : FB_Calibration_Manager;"
fb_insert = """fbCalibVerifyMethane : FB_Calibration_Manager;
fbCalibFloorTemp1 : FB_Sensor_Calibration_Processor;
fbCalibVerifyFloorTemp1 : FB_Calibration_Manager;"""

if "fbCalibFloorTemp1 : FB_Sensor_Calibration_Processor;" not in prg_text:
    if fb_anchor not in prg_text:
        raise SystemExit("FB anchor not found in PRG_System.st")
    prg_text = prg_text.replace(fb_anchor, fb_insert, 1)

var_anchor = "L_Methane_Calibrated : REAL;"
var_insert = """L_Methane_Calibrated : REAL;
L_FloorTemp1_Calibrated : REAL;"""

if "L_FloorTemp1_Calibrated : REAL;" not in prg_text:
    if var_anchor not in prg_text:
        raise SystemExit("Value var anchor not found in PRG_System.st")
    prg_text = prg_text.replace(var_anchor, var_insert, 1)

ts_anchor = "L_Methane_Verification_Active_Prev : BOOL;"
ts_insert = """L_Methane_Verification_Active_Prev : BOOL;
L_FloorTemp1_Calib_TS_Prev : UDINT;
L_FloorTemp1_Verification_Active_Prev : BOOL;"""

if "L_FloorTemp1_Calib_TS_Prev : UDINT;" not in prg_text:
    if ts_anchor not in prg_text:
        raise SystemExit("TS anchor not found in PRG_System.st")
    prg_text = prg_text.replace(ts_anchor, ts_insert, 1)

# ------------------------------------------------------------
# 3) Insert floor temperature calibration observer
# ------------------------------------------------------------
anchor_block = """// === METHANE SHADOW EXPORT ===
GVL_Sensor_Shadow.G_Methane_Raw := GVL_STATE.G_Methane_Sensors[1];
GVL_Sensor_Shadow.G_Methane_Processed := L_Methane_Processed;
GVL_Sensor_Shadow.G_Methane_Calibrated := L_Methane_Calibrated;
GVL_Sensor_Shadow.G_Methane_Error := fbSensorMethane.VO_Error;
GVL_Sensor_Shadow.G_Methane_Diag_Code := fbSensorMethane.VO_Diag_Code;

"""

floor_block = """// === METHANE SHADOW EXPORT ===
GVL_Sensor_Shadow.G_Methane_Raw := GVL_STATE.G_Methane_Sensors[1];
GVL_Sensor_Shadow.G_Methane_Processed := L_Methane_Processed;
GVL_Sensor_Shadow.G_Methane_Calibrated := L_Methane_Calibrated;
GVL_Sensor_Shadow.G_Methane_Error := fbSensorMethane.VO_Error;
GVL_Sensor_Shadow.G_Methane_Diag_Code := fbSensorMethane.VO_Diag_Code;

// === FLOOR TEMP 1 CALIBRATION OBSERVER (PILOT) ===
fbCalibFloorTemp1(
    VI_Raw_Value := GVL_STATE.G_Floor_Temps[1],
    VI_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[3]
);
L_FloorTemp1_Calibrated := fbCalibFloorTemp1.VO_Calibrated_Value;

fbCalibVerifyFloorTemp1(
    VI_Raw_Value := GVL_STATE.G_Floor_Temps[1],
    VI_Type := 1,
    VI_Calib_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[3],
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Start_Verification := (
        GVL_CONFIG.G_HMI_Sensor_Calibrations[3].last_calibration_timestamp <> 0 AND
        GVL_CONFIG.G_HMI_Sensor_Calibrations[3].last_calibration_timestamp <> L_FloorTemp1_Calib_TS_Prev
    )
);

GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Active := TRUE;
GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Verification_Active :=
    fbCalibVerifyFloorTemp1.VO_Verification_Active;
GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Verification_Failed :=
    fbCalibVerifyFloorTemp1.VO_Verification_Failed;
GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Deviation_Percent :=
    fbCalibVerifyFloorTemp1.VO_Deviation_Percent;

IF GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Verification_Failed THEN
    GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Summary_Text := 'FloorTemp1 verification failed';
ELSIF GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Verification_Active THEN
    GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Summary_Text := 'FloorTemp1 verification active';
ELSE
    GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Summary_Text := 'FloorTemp1 verification idle';
END_IF;

IF L_FloorTemp1_Verification_Active_Prev AND
   (NOT fbCalibVerifyFloorTemp1.VO_Verification_Active) THEN
    GVL_CONFIG.G_HMI_Sensor_Calibrations[3].verification_passed :=
        NOT fbCalibVerifyFloorTemp1.VO_Verification_Failed;
END_IF;

L_FloorTemp1_Verification_Active_Prev := fbCalibVerifyFloorTemp1.VO_Verification_Active;
L_FloorTemp1_Calib_TS_Prev := GVL_CONFIG.G_HMI_Sensor_Calibrations[3].last_calibration_timestamp;

"""

if "// === FLOOR TEMP 1 CALIBRATION OBSERVER (PILOT) ===" not in prg_text:
    if anchor_block not in prg_text:
        raise SystemExit("Floor temp insertion anchor block not found in PRG_System.st")
    prg_text = prg_text.replace(anchor_block, floor_block, 1)

prg.write_text(prg_text, encoding="utf-8")
print("OK: floor temperature calibration observer integrated")
