from pathlib import Path

prg = Path("PRG_System.st")
text = prg.read_text(encoding="utf-8")

# ------------------------------------------------------------
# 1) Replace scalar FB with array
# ------------------------------------------------------------
old_fb = """fbCalibDHWPressure : FB_Sensor_Calibration_Processor;
fbCalibVerifyDHWPressure : FB_Calibration_Manager;"""

new_fb = """fbCalibPressureFamily : ARRAY[1..1] OF FB_Sensor_Calibration_Processor;
fbCalibVerifyPressureFamily : ARRAY[1..1] OF FB_Calibration_Manager;"""

if old_fb not in text:
    raise SystemExit("Pressure FB block not found exactly")

text = text.replace(old_fb, new_fb, 1)

# ------------------------------------------------------------
# 2) Replace scalar vars with family arrays
# ------------------------------------------------------------
old_vals = """L_DHWPressure_Calibrated : REAL;"""

new_vals = """L_DHWPressure_Calibrated : REAL;
L_PressureFamily_Raw : REAL;
L_PressureFamily_Calibrated : ARRAY[1..1] OF REAL;"""

text = text.replace(old_vals, new_vals, 1)

old_prev = """L_DHWPressure_Calib_TS_Prev : UDINT;
    L_DHWPressure_Verification_Active_Prev : BOOL;"""

new_prev = """L_PressureFamily_Calib_TS_Prev : ARRAY[1..1] OF UDINT;
    L_PressureFamily_Verification_Active_Prev : ARRAY[1..1] OF BOOL;"""

text = text.replace(old_prev, new_prev, 1)

# add index
if "L_PressureFamily_i : INT;" not in text:
    anchor = "L_GasFamily_i : INT;"
    text = text.replace(anchor, anchor + "\n    L_PressureFamily_i : INT;", 1)

# ------------------------------------------------------------
# 3) Replace scalar pressure block with loop
# ------------------------------------------------------------
old_block = """// === PRESSURE FAMILY PILOT ==="""

if old_block not in text:
    raise SystemExit("Pressure pilot block marker not found")

# cut whole block manually by marker range
start = text.index("// === PRESSURE FAMILY PILOT ===")
end = text.index("// === SMOKE SHADOW EXEC ===", start)

new_block = """// === PRESSURE FAMILY GENERIC LOOP ===
// Mapping:
// 1 -> DHW pressure (record[7])
FOR L_PressureFamily_i := 1 TO 1 DO

    L_PressureFamily_Raw := GVL_STATE.G_DHW_Pressure;

    fbCalibPressureFamily[L_PressureFamily_i](
        VI_Raw_Value := L_PressureFamily_Raw,
        VI_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[7]
    );
    L_PressureFamily_Calibrated[L_PressureFamily_i] :=
        fbCalibPressureFamily[L_PressureFamily_i].VO_Calibrated_Value;

    fbCalibVerifyPressureFamily[L_PressureFamily_i](
        VI_Raw_Value := L_PressureFamily_Raw,
        VI_Type := 2,
        VI_Calib_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[7],
        VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
        VI_Start_Verification := (
            GVL_CONFIG.G_HMI_Sensor_Calibrations[7].last_calibration_timestamp <> 0 AND
            GVL_CONFIG.G_HMI_Sensor_Calibrations[7].last_calibration_timestamp <> L_PressureFamily_Calib_TS_Prev[1]
        )
    );

    L_DHWPressure_Calibrated := L_PressureFamily_Calibrated[1];

    GVL_STATUS.G_Diagnostics.Calibration_DHWPressure_Active := TRUE;
    GVL_STATUS.G_Diagnostics.Calibration_DHWPressure_Calibrated_Value := L_DHWPressure_Calibrated;
    GVL_STATUS.G_Diagnostics.Calibration_DHWPressure_Verification_Active :=
        fbCalibVerifyPressureFamily[1].VO_Verification_Active;
    GVL_STATUS.G_Diagnostics.Calibration_DHWPressure_Verification_Failed :=
        fbCalibVerifyPressureFamily[1].VO_Verification_Failed;
    GVL_STATUS.G_Diagnostics.Calibration_DHWPressure_Deviation_Percent :=
        fbCalibVerifyPressureFamily[1].VO_Deviation_Percent;

    IF L_PressureFamily_Verification_Active_Prev[1] AND
       (NOT fbCalibVerifyPressureFamily[1].VO_Verification_Active) THEN
        GVL_CONFIG.G_HMI_Sensor_Calibrations[7].verification_passed :=
            NOT fbCalibVerifyPressureFamily[1].VO_Verification_Failed;
    END_IF;

    L_PressureFamily_Verification_Active_Prev[1] :=
        fbCalibVerifyPressureFamily[1].VO_Verification_Active;

    L_PressureFamily_Calib_TS_Prev[1] :=
        GVL_CONFIG.G_HMI_Sensor_Calibrations[7].last_calibration_timestamp;

END_FOR;
"""

text = text[:start] + new_block + text[end:]

prg.write_text(text, encoding="utf-8")
print("OK: pressure family generic loop integrated")
