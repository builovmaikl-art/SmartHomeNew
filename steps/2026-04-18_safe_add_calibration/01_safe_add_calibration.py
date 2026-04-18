from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

# ------------------------------------------------------------
# 1) ADD VAR (очень аккуратно)
# ------------------------------------------------------------
if "fbCalibCO" not in text:
    text = text.replace(
        "fbSensorCO : FB_Sensor_Analog_Processing;",
        "fbSensorCO : FB_Sensor_Analog_Processing;\nfbCalibCO  : FB_Sensor_Calibration_Processor;",
        1
    )

# ------------------------------------------------------------
# 2) ADD CALL (без замены старого блока)
# ------------------------------------------------------------
marker = "L_CO_Processed := fbSensorCO.VO_Value;"

if marker not in text:
    raise SystemExit("Expected skeleton assignment not found")

insertion = """L_CO_Processed := fbSensorCO.VO_Value;

// === SENSOR CALIBRATION (SHADOW ADD) ===
fbCalibCO(
    VI_Raw_Value := L_CO_Processed,
    VI_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[1]
);
"""

text = text.replace(marker, insertion, 1)

path.write_text(text, encoding="utf-8")
print("OK: safely added calibration without touching VAR block structure")
