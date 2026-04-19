from pathlib import Path

# ------------------------------------------------------------
# 1) Extend diagnostics
# ------------------------------------------------------------
dut = Path("ST_System_Diagnostics.dut")
dut_text = dut.read_text(encoding="utf-8")

pressure_dut_block = """    // === PRESSURE FAMILY PILOT ===
    Calibration_DHWPressure_Active : BOOL;
    Calibration_DHWPressure_Verification_Active : BOOL;
    Calibration_DHWPressure_Verification_Failed : BOOL;
    Calibration_DHWPressure_Deviation_Percent : REAL;
    Calibration_DHWPressure_Calibrated_Value : REAL;
    Calibration_DHWPressure_Summary_Text : STRING(160);

"""

if "Calibration_DHWPressure_Active : BOOL;" not in dut_text:
    marker = "\nEND_STRUCT\nEND_TYPE"
    if marker not in dut_text:
        raise SystemExit("END_STRUCT marker not found in ST_System_Diagnostics.dut")
    dut_text = dut_text.replace(marker, "\n" + pressure_dut_block + "END_STRUCT\nEND_TYPE", 1)

dut.write_text(dut_text, encoding="utf-8")

# ------------------------------------------------------------
# 2) Extend PRG_System VAR
# ------------------------------------------------------------
prg = Path("PRG_System.st")
text = prg.read_text(encoding="utf-8")

fb_anchor = "fbCalibRoomHum1 : FB_Sensor_Calibration_Processor;"
if "fbCalibDHWPressure : FB_Sensor_Calibration_Processor;" not in text:
    if fb_anchor not in text:
        raise SystemExit("FB anchor not found")
    text = text.replace(
        fb_anchor,
        fb_anchor + "\nfbCalibDHWPressure : FB_Sensor_Calibration_Processor;\nfbCalibVerifyDHWPressure : FB_Calibration_Manager;",
        1
    )

val_anchor = "L_RoomHum1_Calibrated : REAL;"
if "L_DHWPressure_Calibrated : REAL;" not in text:
    if val_anchor not in text:
        raise SystemExit("Value var anchor not found")
    text = text.replace(
        val_anchor,
        val_anchor + "\nL_DHWPressure_Calibrated : REAL;",
        1
    )

prev_anchor = "L_GasFamily_i : INT;"
if "L_DHWPressure_Calib_TS_Prev : UDINT;" not in text:
    if prev_anchor not in text:
        raise SystemExit("Prev-state anchor not found")
    text = text.replace(
        prev_anchor,
        prev_anchor + "\n    L_DHWPressure_Calib_TS_Prev : UDINT;\n    L_DHWPressure_Verification_Active_Prev : BOOL;",
        1
    )

# ------------------------------------------------------------
# 3) Insert pressure pilot right after humidity pilot
# ------------------------------------------------------------
old = """GVL_STATUS.G_Diagnostics.Calibration_RoomHum1_Summary_Text := 'RoomHum1 calibration pilot active';

// === SMOKE SHADOW EXEC ===
"""

new = """GVL_STATUS.G_Diagnostics.Calibration_RoomHum1_Summary_Text := 'RoomHum1 calibration pilot active';

// === PRESSURE FAMILY PILOT ===
fbCalibDHWPressure(
    VI_Raw_Value := GVL_STATE.G_DHW_Pressure,
    VI_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[7]
);
L_DHWPressure_Calibrated := fbCalibDHWPressure.VO_Calibrated_Value;

fbCalibVerifyDHWPressure(
    VI_Raw_Value := GVL_STATE.G_DHW_Pressure,
    VI_Type := 2,
    VI_Calib_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[7],
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Start_Verification := (
        GVL_CONFIG.G_HMI_Sensor_Calibrations[7].last_calibration_timestamp <> 0 AND
        GVL_CONFIG.G_HMI_Sensor_Calibrations[7].last_calibration_timestamp <> L_DHWPressure_Calib_TS_Prev
    )
);

GVL_STATUS.G_Diagnostics.Calibration_DHWPressure_Active := TRUE;
GVL_STATUS.G_Diagnostics.Calibration_DHWPressure_Calibrated_Value := L_DHWPressure_Calibrated;
GVL_STATUS.G_Diagnostics.Calibration_DHWPressure_Verification_Active := fbCalibVerifyDHWPressure.VO_Verification_Active;
GVL_STATUS.G_Diagnostics.Calibration_DHWPressure_Verification_Failed := fbCalibVerifyDHWPressure.VO_Verification_Failed;
GVL_STATUS.G_Diagnostics.Calibration_DHWPressure_Deviation_Percent := fbCalibVerifyDHWPressure.VO_Deviation_Percent;

IF GVL_STATUS.G_Diagnostics.Calibration_DHWPressure_Verification_Failed THEN
    GVL_STATUS.G_Diagnostics.Calibration_DHWPressure_Summary_Text := 'DHW pressure verification failed';
ELSIF GVL_STATUS.G_Diagnostics.Calibration_DHWPressure_Verification_Active THEN
    GVL_STATUS.G_Diagnostics.Calibration_DHWPressure_Summary_Text := 'DHW pressure verification active';
ELSE
    GVL_STATUS.G_Diagnostics.Calibration_DHWPressure_Summary_Text := 'DHW pressure verification idle';
END_IF;

IF L_DHWPressure_Verification_Active_Prev AND
   (NOT fbCalibVerifyDHWPressure.VO_Verification_Active) THEN
    GVL_CONFIG.G_HMI_Sensor_Calibrations[7].verification_passed :=
        NOT fbCalibVerifyDHWPressure.VO_Verification_Failed;
END_IF;

L_DHWPressure_Verification_Active_Prev := fbCalibVerifyDHWPressure.VO_Verification_Active;
L_DHWPressure_Calib_TS_Prev := GVL_CONFIG.G_HMI_Sensor_Calibrations[7].last_calibration_timestamp;

// === SMOKE SHADOW EXEC ===
"""

if "// === PRESSURE FAMILY PILOT ===" not in text:
    if old not in text:
        raise SystemExit("Exact insertion point after humidity pilot not found")
    text = text.replace(old, new, 1)

prg.write_text(text, encoding="utf-8")
print("OK: pressure family pilot integrated")
