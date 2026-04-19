from pathlib import Path

# ------------------------------------------------------------
# 1) Extend diagnostics
# ------------------------------------------------------------
dut = Path("ST_System_Diagnostics.dut")
dut_text = dut.read_text(encoding="utf-8")

anchor = "    Calibration_Verification_Summary_Text : STRING(160);\n\n\n\nEND_STRUCT"
insert = """    Calibration_Verification_Summary_Text : STRING(160);

    // === CALIBRATION VERIFICATION TELEMETRY ===
    Calibration_CO_Verification_Event_Count : UDINT;
    Calibration_Methane_Verification_Event_Count : UDINT;
    Calibration_Last_Event_Time_MS : UDINT;
    Calibration_Last_Event_Text : STRING(160);



END_STRUCT"""

if "Calibration_CO_Verification_Event_Count : UDINT;" not in dut_text:
    if anchor not in dut_text:
        raise SystemExit("Diagnostics anchor not found in ST_System_Diagnostics.dut")
    dut_text = dut_text.replace(anchor, insert, 1)

dut.write_text(dut_text, encoding="utf-8")

# ------------------------------------------------------------
# 2) Insert telemetry after write-back block
# ------------------------------------------------------------
prg = Path("PRG_System.st")
text = prg.read_text(encoding="utf-8")

anchor_block = """L_CO_Verification_Active_Prev := fbCalibVerifyCO.VO_Verification_Active;
L_Methane_Verification_Active_Prev := fbCalibVerifyMethane.VO_Verification_Active;

L_CO_Calib_TS_Prev := GVL_CONFIG.G_HMI_Sensor_Calibrations[1].last_calibration_timestamp;
L_Methane_Calib_TS_Prev := GVL_CONFIG.G_HMI_Sensor_Calibrations[2].last_calibration_timestamp;

"""

telemetry_block = """// === CALIBRATION VERIFICATION TELEMETRY ===
IF L_CO_Verification_Active_Prev AND
   (NOT fbCalibVerifyCO.VO_Verification_Active) THEN
    GVL_STATUS.G_Diagnostics.Calibration_CO_Verification_Event_Count :=
        GVL_STATUS.G_Diagnostics.Calibration_CO_Verification_Event_Count + 1;
    GVL_STATUS.G_Diagnostics.Calibration_Last_Event_Time_MS := GVL_STATUS.G_System_Time_MS;

    IF fbCalibVerifyCO.VO_Verification_Failed THEN
        GVL_STATUS.G_Diagnostics.Calibration_Last_Event_Text := 'CO verification failed';
    ELSE
        GVL_STATUS.G_Diagnostics.Calibration_Last_Event_Text := 'CO verification passed';
    END_IF;
END_IF;

IF L_Methane_Verification_Active_Prev AND
   (NOT fbCalibVerifyMethane.VO_Verification_Active) THEN
    GVL_STATUS.G_Diagnostics.Calibration_Methane_Verification_Event_Count :=
        GVL_STATUS.G_Diagnostics.Calibration_Methane_Verification_Event_Count + 1;
    GVL_STATUS.G_Diagnostics.Calibration_Last_Event_Time_MS := GVL_STATUS.G_System_Time_MS;

    IF fbCalibVerifyMethane.VO_Verification_Failed THEN
        GVL_STATUS.G_Diagnostics.Calibration_Last_Event_Text := 'Methane verification failed';
    ELSE
        GVL_STATUS.G_Diagnostics.Calibration_Last_Event_Text := 'Methane verification passed';
    END_IF;
END_IF;

L_CO_Verification_Active_Prev := fbCalibVerifyCO.VO_Verification_Active;
L_Methane_Verification_Active_Prev := fbCalibVerifyMethane.VO_Verification_Active;

L_CO_Calib_TS_Prev := GVL_CONFIG.G_HMI_Sensor_Calibrations[1].last_calibration_timestamp;
L_Methane_Calib_TS_Prev := GVL_CONFIG.G_HMI_Sensor_Calibrations[2].last_calibration_timestamp;

"""

if "// === CALIBRATION VERIFICATION TELEMETRY ===" not in text:
    if anchor_block not in text:
        raise SystemExit("Telemetry insertion anchor block not found in PRG_System.st")
    text = text.replace(anchor_block, telemetry_block, 1)

prg.write_text(text, encoding="utf-8")
print("OK: calibration verification telemetry integrated")
