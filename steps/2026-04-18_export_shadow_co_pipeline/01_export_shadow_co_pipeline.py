from pathlib import Path

# ------------------------------------------------------------
# 1) CREATE GVL_Sensor_Shadow
# ------------------------------------------------------------
Path("GVL_Sensor_Shadow.gvl").write_text(
"""VAR_GLOBAL
    // === CO SHADOW PIPELINE EXPORT ===
    G_CO_Raw : REAL;
    G_CO_Processed : REAL;
    G_CO_Calibrated : REAL;
    G_CO_Error : BOOL;
    G_CO_Diag_Code : WORD;
END_VAR
""",
    encoding="utf-8"
)

# ------------------------------------------------------------
# 2) PATCH PRG_System.st
# ------------------------------------------------------------
path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

marker = "L_CO_Calibrated := fbCalibCO.VO_Calibrated_Value;"
if marker not in text:
    raise SystemExit("Calibration marker not found")

export_block = """L_CO_Calibrated := fbCalibCO.VO_Calibrated_Value;

// === SHADOW EXPORT ===
GVL_Sensor_Shadow.G_CO_Raw := GVL_STATE.G_CO_Sensors[1];
GVL_Sensor_Shadow.G_CO_Processed := L_CO_Processed;
GVL_Sensor_Shadow.G_CO_Calibrated := L_CO_Calibrated;
GVL_Sensor_Shadow.G_CO_Error := fbSensorCO.VO_Error;
GVL_Sensor_Shadow.G_CO_Diag_Code := fbSensorCO.VO_Diag_Code;
"""

if "GVL_Sensor_Shadow.G_CO_Processed" not in text:
    text = text.replace(marker, export_block, 1)

path.write_text(text, encoding="utf-8")

print("OK: shadow CO pipeline exported to GVL")
