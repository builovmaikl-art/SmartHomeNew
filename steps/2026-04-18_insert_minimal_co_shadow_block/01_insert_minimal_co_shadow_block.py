from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

# 1) Add missing VARs only by exact declarations
sensor_decl = "fbSensorCO : FB_Sensor_Analog_Processing;"
if sensor_decl not in text:
    raise SystemExit("fbSensorCO declaration not found")

if "fbCalibCO  : FB_Sensor_Calibration_Processor;" not in text:
    text = text.replace(
        sensor_decl,
        sensor_decl + "\nfbCalibCO  : FB_Sensor_Calibration_Processor;",
        1
    )

processed_decl = "L_CO_Processed : REAL;"
if processed_decl not in text:
    raise SystemExit("L_CO_Processed declaration not found")

if "L_CO_Calibrated : REAL;" not in text:
    text = text.replace(
        processed_decl,
        processed_decl + "\nL_CO_Calibrated : REAL;",
        1
    )

# 2) Insert executable block before lifetime section
lifetime_marker = "// === LIFETIME UPDATE ==="
if lifetime_marker not in text:
    raise SystemExit("LIFETIME marker not found")

block = """// === SENSOR PROCESSING (SHADOW EXEC) ===
fbSensorCO(
    VI_Raw_Value := REAL_TO_WORD(GVL_STATE.G_CO_Sensors[1]),
    VI_Sensor_Type := 0,
    VI_Min_Scale := 0.0,
    VI_Max_Scale := 100.0,
    VI_Offset := 0.0,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);
L_CO_Processed := fbSensorCO.VO_Value;

fbCalibCO(
    VI_Raw_Value := L_CO_Processed,
    VI_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[1]
);
L_CO_Calibrated := fbCalibCO.VO_Calibrated_Value;

"""

if "// === SENSOR PROCESSING (SHADOW EXEC) ===" not in text:
    text = text.replace(lifetime_marker, block + lifetime_marker, 1)

path.write_text(text, encoding="utf-8")
print("OK: inserted minimal executable CO shadow block")
