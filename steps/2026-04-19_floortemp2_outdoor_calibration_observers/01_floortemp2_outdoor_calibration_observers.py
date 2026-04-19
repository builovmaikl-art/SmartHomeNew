from pathlib import Path

# ------------------------------------------------------------
# 1) Extend diagnostics
# ------------------------------------------------------------
dut = Path("ST_System_Diagnostics.dut")
dut_text = dut.read_text(encoding="utf-8")

anchor = "    Calibration_FloorTemp1_Summary_Text : STRING(160);\n\n\n\nEND_STRUCT"
insert = """    Calibration_FloorTemp1_Summary_Text : STRING(160);

    // === FLOOR TEMP 2 CALIBRATION OBSERVER ===
    Calibration_FloorTemp2_Active : BOOL;
    Calibration_FloorTemp2_Verification_Active : BOOL;
    Calibration_FloorTemp2_Verification_Failed : BOOL;
    Calibration_FloorTemp2_Deviation_Percent : REAL;
    Calibration_FloorTemp2_Summary_Text : STRING(160);

    // === OUTDOOR TEMP CALIBRATION OBSERVER ===
    Calibration_OutdoorTemp_Active : BOOL;
    Calibration_OutdoorTemp_Verification_Active : BOOL;
    Calibration_OutdoorTemp_Verification_Failed : BOOL;
    Calibration_OutdoorTemp_Deviation_Percent : REAL;
    Calibration_OutdoorTemp_Summary_Text : STRING(160);



END_STRUCT"""

if "Calibration_FloorTemp2_Active : BOOL;" not in dut_text:
    if anchor not in dut_text:
        raise SystemExit("Diagnostics anchor not found in ST_System_Diagnostics.dut")
    dut_text = dut_text.replace(anchor, insert, 1)

dut.write_text(dut_text, encoding="utf-8")

# ------------------------------------------------------------
# 2) Extend PRG_System VAR
# ------------------------------------------------------------
prg = Path("PRG_System.st")
prg_text = prg.read_text(encoding="utf-8")

fb_anchor = "fbCalibVerifyFloorTemp1 : FB_Calibration_Manager;"
fb_insert = """fbCalibVerifyFloorTemp1 : FB_Calibration_Manager;
fbCalibFloorTemp2 : FB_Sensor_Calibration_Processor;
fbCalibVerifyFloorTemp2 : FB_Calibration_Manager;
fbCalibOutdoorTemp : FB_Sensor_Calibration_Processor;
fbCalibVerifyOutdoorTemp : FB_Calibration_Manager;"""

if "fbCalibFloorTemp2 : FB_Sensor_Calibration_Processor;" not in prg_text:
    if fb_anchor not in prg_text:
        raise SystemExit("FB anchor not found in PRG_System.st")
    prg_text = prg_text.replace(fb_anchor, fb_insert, 1)

val_anchor = "L_FloorTemp1_Calibrated : REAL;"
val_insert = """L_FloorTemp1_Calibrated : REAL;
L_FloorTemp2_Calibrated : REAL;
L_OutdoorTemp_Calibrated : REAL;"""

if "L_FloorTemp2_Calibrated : REAL;" not in prg_text:
    if val_anchor not in prg_text:
        raise SystemExit("Value anchor not found in PRG_System.st")
    prg_text = prg_text.replace(val_anchor, val_insert, 1)

ts_anchor = "L_FloorTemp1_Verification_Active_Prev : BOOL;"
ts_insert = """L_FloorTemp1_Verification_Active_Prev : BOOL;
L_FloorTemp2_Calib_TS_Prev : UDINT;
L_FloorTemp2_Verification_Active_Prev : BOOL;
L_OutdoorTemp_Calib_TS_Prev : UDINT;
L_OutdoorTemp_Verification_Active_Prev : BOOL;"""

if "L_FloorTemp2_Calib_TS_Prev : UDINT;" not in prg_text:
    if ts_anchor not in prg_text:
        raise SystemExit("TS anchor not found in PRG_System.st")
    prg_text = prg_text.replace(ts_anchor, ts_insert, 1)

# ------------------------------------------------------------
# 3) Insert FloorTemp2 + OutdoorTemp observer block
# ------------------------------------------------------------
anchor_block = """L_FloorTemp1_Verification_Active_Prev := fbCalibVerifyFloorTemp1.VO_Verification_Active;
L_FloorTemp1_Calib_TS_Prev := GVL_CONFIG.G_HMI_Sensor_Calibrations[3].last_calibration_timestamp;

"""

new_block = """L_FloorTemp1_Verification_Active_Prev := fbCalibVerifyFloorTemp1.VO_Verification_Active;
L_FloorTemp1_Calib_TS_Prev := GVL_CONFIG.G_HMI_Sensor_Calibrations[3].last_calibration_timestamp;

// === FLOOR TEMP 2 CALIBRATION OBSERVER ===
fbCalibFloorTemp2(
    VI_Raw_Value := GVL_STATE.G_Floor_Temps[2],
    VI_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[4]
);
L_FloorTemp2_Calibrated := fbCalibFloorTemp2.VO_Calibrated_Value;

fbCalibVerifyFloorTemp2(
    VI_Raw_Value := GVL_STATE.G_Floor_Temps[2],
    VI_Type := 1,
    VI_Calib_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[4],
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Start_Verification := (
        GVL_CONFIG.G_HMI_Sensor_Calibrations[4].last_calibration_timestamp <> 0 AND
        GVL_CONFIG.G_HMI_Sensor_Calibrations[4].last_calibration_timestamp <> L_FloorTemp2_Calib_TS_Prev
    )
);

GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Active := TRUE;
GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Verification_Active :=
    fbCalibVerifyFloorTemp2.VO_Verification_Active;
GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Verification_Failed :=
    fbCalibVerifyFloorTemp2.VO_Verification_Failed;
GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Deviation_Percent :=
    fbCalibVerifyFloorTemp2.VO_Deviation_Percent;

IF GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Verification_Failed THEN
    GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Summary_Text := 'FloorTemp2 verification failed';
ELSIF GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Verification_Active THEN
    GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Summary_Text := 'FloorTemp2 verification active';
ELSE
    GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Summary_Text := 'FloorTemp2 verification idle';
END_IF;

IF L_FloorTemp2_Verification_Active_Prev AND
   (NOT fbCalibVerifyFloorTemp2.VO_Verification_Active) THEN
    GVL_CONFIG.G_HMI_Sensor_Calibrations[4].verification_passed :=
        NOT fbCalibVerifyFloorTemp2.VO_Verification_Failed;
END_IF;

L_FloorTemp2_Verification_Active_Prev := fbCalibVerifyFloorTemp2.VO_Verification_Active;
L_FloorTemp2_Calib_TS_Prev := GVL_CONFIG.G_HMI_Sensor_Calibrations[4].last_calibration_timestamp;

// === OUTDOOR TEMP CALIBRATION OBSERVER ===
fbCalibOutdoorTemp(
    VI_Raw_Value := GVL_STATE.G_Outdoor_Temp,
    VI_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[5]
);
L_OutdoorTemp_Calibrated := fbCalibOutdoorTemp.VO_Calibrated_Value;

fbCalibVerifyOutdoorTemp(
    VI_Raw_Value := GVL_STATE.G_Outdoor_Temp,
    VI_Type := 1,
    VI_Calib_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[5],
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Start_Verification := (
        GVL_CONFIG.G_HMI_Sensor_Calibrations[5].last_calibration_timestamp <> 0 AND
        GVL_CONFIG.G_HMI_Sensor_Calibrations[5].last_calibration_timestamp <> L_OutdoorTemp_Calib_TS_Prev
    )
);

GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Active := TRUE;
GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Verification_Active :=
    fbCalibVerifyOutdoorTemp.VO_Verification_Active;
GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Verification_Failed :=
    fbCalibVerifyOutdoorTemp.VO_Verification_Failed;
GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Deviation_Percent :=
    fbCalibVerifyOutdoorTemp.VO_Deviation_Percent;

IF GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Verification_Failed THEN
    GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Summary_Text := 'OutdoorTemp verification failed';
ELSIF GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Verification_Active THEN
    GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Summary_Text := 'OutdoorTemp verification active';
ELSE
    GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Summary_Text := 'OutdoorTemp verification idle';
END_IF;

IF L_OutdoorTemp_Verification_Active_Prev AND
   (NOT fbCalibVerifyOutdoorTemp.VO_Verification_Active) THEN
    GVL_CONFIG.G_HMI_Sensor_Calibrations[5].verification_passed :=
        NOT fbCalibVerifyOutdoorTemp.VO_Verification_Failed;
END_IF;

L_OutdoorTemp_Verification_Active_Prev := fbCalibVerifyOutdoorTemp.VO_Verification_Active;
L_OutdoorTemp_Calib_TS_Prev := GVL_CONFIG.G_HMI_Sensor_Calibrations[5].last_calibration_timestamp;

"""

if "// === FLOOR TEMP 2 CALIBRATION OBSERVER ===" not in prg_text:
    if anchor_block not in prg_text:
        raise SystemExit("Insertion anchor block for FloorTemp2/OutdoorTemp not found in PRG_System.st")
    prg_text = prg_text.replace(anchor_block, new_block, 1)

prg.write_text(prg_text, encoding="utf-8")
print("OK: FloorTemp2 and OutdoorTemp calibration observers integrated")
