from pathlib import Path

# ------------------------------------------------------------
# 1) Extend diagnostics
# ------------------------------------------------------------
dut = Path("ST_System_Diagnostics.dut")
dut_text = dut.read_text(encoding="utf-8")

anchor = "    Heating_Cooldown_Text : STRING(160);\n\n\n\nEND_STRUCT"
insert = """    Heating_Cooldown_Text : STRING(160);

    // === CALIBRATION VERIFICATION OBSERVER ===
    Calibration_CO_Verification_Active : BOOL;
    Calibration_CO_Verification_Failed : BOOL;
    Calibration_CO_Deviation_Percent : REAL;

    Calibration_Methane_Verification_Active : BOOL;
    Calibration_Methane_Verification_Failed : BOOL;
    Calibration_Methane_Deviation_Percent : REAL;

    Calibration_Verification_Summary_Text : STRING(160);



END_STRUCT"""

if "Calibration_CO_Verification_Active : BOOL;" not in dut_text:
    if anchor not in dut_text:
        raise SystemExit("Diagnostics anchor not found in ST_System_Diagnostics.dut")
    dut_text = dut_text.replace(anchor, insert, 1)

dut.write_text(dut_text, encoding="utf-8")

# ------------------------------------------------------------
# 2) Extend PRG_System VAR
# ------------------------------------------------------------
prg = Path("PRG_System.st")
prg_text = prg.read_text(encoding="utf-8")

var_anchor = "fbCalibMethane  : FB_Sensor_Calibration_Processor;"
var_insert = """fbCalibMethane  : FB_Sensor_Calibration_Processor;
fbCalibVerifyCO : FB_Calibration_Manager;
fbCalibVerifyMethane : FB_Calibration_Manager;"""

if "fbCalibVerifyCO : FB_Calibration_Manager;" not in prg_text:
    if var_anchor not in prg_text:
        raise SystemExit("Calibration FB anchor not found in PRG_System.st")
    prg_text = prg_text.replace(var_anchor, var_insert, 1)

prev_anchor = "L_Heating_Zone_Lock_Hold_MS : UDINT;"
prev_insert = """L_Heating_Zone_Lock_Hold_MS : UDINT;
L_CO_Calib_TS_Prev : UDINT;
L_Methane_Calib_TS_Prev : UDINT;"""

if "L_CO_Calib_TS_Prev : UDINT;" not in prg_text:
    if prev_anchor not in prg_text:
        raise SystemExit("Calibration prev-ts anchor not found in PRG_System.st")
    prg_text = prg_text.replace(prev_anchor, prev_insert, 1)

# ------------------------------------------------------------
# 3) Insert observer block right after live calibration
# ------------------------------------------------------------
anchor_block = """fbCalibMethane(
    VI_Raw_Value := L_Methane_Processed,
    VI_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[2]
);
L_Methane_Calibrated := fbCalibMethane.VO_Calibrated_Value;

"""

verification_block = """fbCalibMethane(
    VI_Raw_Value := L_Methane_Processed,
    VI_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[2]
);
L_Methane_Calibrated := fbCalibMethane.VO_Calibrated_Value;

// === CALIBRATION VERIFICATION OBSERVER ===
fbCalibVerifyCO(
    VI_Raw_Value := L_CO_Processed,
    VI_Type := 3,
    VI_Calib_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[1],
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Start_Verification := (
        GVL_CONFIG.G_HMI_Sensor_Calibrations[1].last_calibration_timestamp <> 0 AND
        GVL_CONFIG.G_HMI_Sensor_Calibrations[1].last_calibration_timestamp <> L_CO_Calib_TS_Prev
    )
);

fbCalibVerifyMethane(
    VI_Raw_Value := L_Methane_Processed,
    VI_Type := 3,
    VI_Calib_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[2],
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Start_Verification := (
        GVL_CONFIG.G_HMI_Sensor_Calibrations[2].last_calibration_timestamp <> 0 AND
        GVL_CONFIG.G_HMI_Sensor_Calibrations[2].last_calibration_timestamp <> L_Methane_Calib_TS_Prev
    )
);

GVL_STATUS.G_Diagnostics.Calibration_CO_Verification_Active :=
    fbCalibVerifyCO.VO_Verification_Active;
GVL_STATUS.G_Diagnostics.Calibration_CO_Verification_Failed :=
    fbCalibVerifyCO.VO_Verification_Failed;
GVL_STATUS.G_Diagnostics.Calibration_CO_Deviation_Percent :=
    fbCalibVerifyCO.VO_Deviation_Percent;

GVL_STATUS.G_Diagnostics.Calibration_Methane_Verification_Active :=
    fbCalibVerifyMethane.VO_Verification_Active;
GVL_STATUS.G_Diagnostics.Calibration_Methane_Verification_Failed :=
    fbCalibVerifyMethane.VO_Verification_Failed;
GVL_STATUS.G_Diagnostics.Calibration_Methane_Deviation_Percent :=
    fbCalibVerifyMethane.VO_Deviation_Percent;

IF GVL_STATUS.G_Diagnostics.Calibration_CO_Verification_Failed THEN
    GVL_STATUS.G_Diagnostics.Calibration_Verification_Summary_Text := 'CO calibration verification failed';
ELSIF GVL_STATUS.G_Diagnostics.Calibration_Methane_Verification_Failed THEN
    GVL_STATUS.G_Diagnostics.Calibration_Verification_Summary_Text := 'Methane calibration verification failed';
ELSIF GVL_STATUS.G_Diagnostics.Calibration_CO_Verification_Active OR
      GVL_STATUS.G_Diagnostics.Calibration_Methane_Verification_Active THEN
    GVL_STATUS.G_Diagnostics.Calibration_Verification_Summary_Text := 'Calibration verification active';
ELSE
    GVL_STATUS.G_Diagnostics.Calibration_Verification_Summary_Text := 'Calibration verification idle';
END_IF;

L_CO_Calib_TS_Prev := GVL_CONFIG.G_HMI_Sensor_Calibrations[1].last_calibration_timestamp;
L_Methane_Calib_TS_Prev := GVL_CONFIG.G_HMI_Sensor_Calibrations[2].last_calibration_timestamp;

"""

if "// === CALIBRATION VERIFICATION OBSERVER ===" not in prg_text:
    if anchor_block not in prg_text:
        raise SystemExit("Calibration insertion anchor block not found in PRG_System.st")
    prg_text = prg_text.replace(anchor_block, verification_block, 1)

prg.write_text(prg_text, encoding="utf-8")
print("OK: calibration verification observer integrated")
