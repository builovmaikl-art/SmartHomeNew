from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

# 1) Add VARs by exact line insertion only
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

# 2) Add calibration call after the existing processed assignment
marker = "L_CO_Processed := fbSensorCO.VO_Value;"
if marker not in text:
    raise SystemExit("CO processed assignment marker not found")

snippet = """L_CO_Processed := fbSensorCO.VO_Value;

fbCalibCO(
    VI_Raw_Value := L_CO_Processed,
    VI_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[1]
);
L_CO_Calibrated := fbCalibCO.VO_Calibrated_Value;"""

if "L_CO_Calibrated := fbCalibCO.VO_Calibrated_Value;" not in text:
    text = text.replace(marker, snippet, 1)

path.write_text(text, encoding="utf-8")
print("OK: safe local CO calibration added")
