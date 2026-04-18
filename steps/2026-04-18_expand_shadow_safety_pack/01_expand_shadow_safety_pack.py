from pathlib import Path

# ------------------------------------------------------------
# 1) Rewrite GVL_Sensor_Shadow.gvl to full safety shadow pack
# ------------------------------------------------------------
Path("GVL_Sensor_Shadow.gvl").write_text(
"""VAR_GLOBAL
    // === CO SHADOW PIPELINE EXPORT ===
    G_CO_Raw : REAL;
    G_CO_Processed : REAL;
    G_CO_Calibrated : REAL;
    G_CO_Error : BOOL;
    G_CO_Diag_Code : WORD;

    // === METHANE SHADOW PIPELINE EXPORT ===
    G_Methane_Raw : REAL;
    G_Methane_Processed : REAL;
    G_Methane_Calibrated : REAL;
    G_Methane_Error : BOOL;
    G_Methane_Diag_Code : WORD;

    // === SMOKE SHADOW PIPELINE EXPORT ===
    G_Smoke_Raw : BOOL;
    G_Smoke_Detected : BOOL;
END_VAR
""",
    encoding="utf-8"
)

# ------------------------------------------------------------
# 2) Patch PRG_System.st
# ------------------------------------------------------------
path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

# 2.1 Add new VAR declarations by exact line insertions
decls = [
    (
        "fbCalibCO  : FB_Sensor_Calibration_Processor;",
        "fbCalibCO  : FB_Sensor_Calibration_Processor;\n"
        "fbSensorMethane : FB_Sensor_Analog_Processing;\n"
        "fbCalibMethane  : FB_Sensor_Calibration_Processor;\n"
        "fbSmokeDetector : FB_Smoke_Detector;"
    ),
    (
        "L_CO_Calibrated : REAL;",
        "L_CO_Calibrated : REAL;\n"
        "L_Methane_Processed : REAL;\n"
        "L_Methane_Calibrated : REAL;\n"
        "L_Smoke_Detected : BOOL;"
    ),
]

for old, new in decls:
    if old not in text:
        raise SystemExit(f"Declaration anchor not found: {old}")
    if new not in text:
        text = text.replace(old, new, 1)

# 2.2 Insert methane+smoke exec/export block before lifetime section
lifetime_marker = "// === LIFETIME UPDATE ==="
if lifetime_marker not in text:
    raise SystemExit("LIFETIME marker not found")

methane_smoke_block = """// === METHANE SHADOW EXEC ===
fbSensorMethane(
    VI_Raw_Value := REAL_TO_WORD(GVL_STATE.G_Methane_Sensors[1]),
    VI_Sensor_Type := 0,
    VI_Min_Scale := 0.0,
    VI_Max_Scale := 100.0,
    VI_Offset := 0.0,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);
L_Methane_Processed := fbSensorMethane.VO_Value;

fbCalibMethane(
    VI_Raw_Value := L_Methane_Processed,
    VI_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[2]
);
L_Methane_Calibrated := fbCalibMethane.VO_Calibrated_Value;

// === METHANE SHADOW EXPORT ===
GVL_Sensor_Shadow.G_Methane_Raw := GVL_STATE.G_Methane_Sensors[1];
GVL_Sensor_Shadow.G_Methane_Processed := L_Methane_Processed;
GVL_Sensor_Shadow.G_Methane_Calibrated := L_Methane_Calibrated;
GVL_Sensor_Shadow.G_Methane_Error := fbSensorMethane.VO_Error;
GVL_Sensor_Shadow.G_Methane_Diag_Code := fbSensorMethane.VO_Diag_Code;

// === SMOKE SHADOW EXEC ===
fbSmokeDetector(
    VI_Smoke_Signal := GVL_STATE.G_Smoke_Sensors[1]
);
L_Smoke_Detected := fbSmokeDetector.VO_Smoke_Detected;

// === SMOKE SHADOW EXPORT ===
GVL_Sensor_Shadow.G_Smoke_Raw := GVL_STATE.G_Smoke_Sensors[1];
GVL_Sensor_Shadow.G_Smoke_Detected := L_Smoke_Detected;

"""

if "// === METHANE SHADOW EXEC ===" not in text:
    text = text.replace(lifetime_marker, methane_smoke_block + lifetime_marker, 1)

path.write_text(text, encoding="utf-8")
print("OK: expanded shadow safety pack")
