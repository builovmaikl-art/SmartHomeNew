from pathlib import Path

prg = Path("PRG_System.st")
text = prg.read_text(encoding="utf-8")

# ------------------------------------------------------------
# 1) Add prev active vars
# ------------------------------------------------------------
anchor = "L_Methane_Calib_TS_Prev : UDINT;"
insert = """L_Methane_Calib_TS_Prev : UDINT;
L_CO_Verification_Active_Prev : BOOL;
L_Methane_Verification_Active_Prev : BOOL;"""

if "L_CO_Verification_Active_Prev : BOOL;" not in text:
    if anchor not in text:
        raise SystemExit("Writeback VAR anchor not found in PRG_System.st")
    text = text.replace(anchor, insert, 1)

# ------------------------------------------------------------
# 2) Insert write-back after verification summary block
# ------------------------------------------------------------
anchor_block = """L_CO_Calib_TS_Prev := GVL_CONFIG.G_HMI_Sensor_Calibrations[1].last_calibration_timestamp;
L_Methane_Calib_TS_Prev := GVL_CONFIG.G_HMI_Sensor_Calibrations[2].last_calibration_timestamp;

"""

writeback_block = """// === CALIBRATION VERIFICATION WRITE-BACK ===
// write result once on verification completion edge
IF L_CO_Verification_Active_Prev AND
   (NOT fbCalibVerifyCO.VO_Verification_Active) THEN
    GVL_CONFIG.G_HMI_Sensor_Calibrations[1].verification_passed :=
        NOT fbCalibVerifyCO.VO_Verification_Failed;
END_IF;

IF L_Methane_Verification_Active_Prev AND
   (NOT fbCalibVerifyMethane.VO_Verification_Active) THEN
    GVL_CONFIG.G_HMI_Sensor_Calibrations[2].verification_passed :=
        NOT fbCalibVerifyMethane.VO_Verification_Failed;
END_IF;

L_CO_Verification_Active_Prev := fbCalibVerifyCO.VO_Verification_Active;
L_Methane_Verification_Active_Prev := fbCalibVerifyMethane.VO_Verification_Active;

L_CO_Calib_TS_Prev := GVL_CONFIG.G_HMI_Sensor_Calibrations[1].last_calibration_timestamp;
L_Methane_Calib_TS_Prev := GVL_CONFIG.G_HMI_Sensor_Calibrations[2].last_calibration_timestamp;

"""

if "// === CALIBRATION VERIFICATION WRITE-BACK ===" not in text:
    if anchor_block not in text:
        raise SystemExit("Writeback insertion anchor block not found in PRG_System.st")
    text = text.replace(anchor_block, writeback_block, 1)

prg.write_text(text, encoding="utf-8")
print("OK: calibration verification write-back integrated")
