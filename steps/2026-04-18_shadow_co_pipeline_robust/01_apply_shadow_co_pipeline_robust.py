from pathlib import Path
import re

# -------------------------------------------------------------------
# 1) GVL_Sensor_Shadow.gvl
# -------------------------------------------------------------------
gvl_path = Path("GVL_Sensor_Shadow.gvl")
gvl_text = """VAR_GLOBAL
    // === CO SHADOW PIPELINE ===
    G_CO_Raw_Word : WORD;
    G_CO_Processed : REAL;
    G_CO_Calibrated : REAL;
    G_CO_Error : BOOL;
    G_CO_Diag_Code : WORD;
END_VAR
"""
gvl_path.write_text(gvl_text, encoding="utf-8")

# -------------------------------------------------------------------
# 2) PRG_System.st
# -------------------------------------------------------------------
prg_path = Path("PRG_System.st")
text = prg_path.read_text(encoding="utf-8")

# 2.1 Ensure shadow VAR declarations exist and are normalized
var_marker = "// === SENSOR PROCESSING (SHADOW) ==="
if var_marker not in text:
    raise SystemExit("Shadow VAR marker not found in PRG_System.st")

# Replace old short declaration block if present
text = re.sub(
    r"// === SENSOR PROCESSING \(SHADOW\) ===\s*"
    r"fbSensorCO\s*:\s*FB_Sensor_Analog_Processing;\s*"
    r"L_CO_Processed\s*:\s*REAL;\s*",
    """// === SENSOR PROCESSING (SHADOW) ===
fbSensorCO : FB_Sensor_Analog_Processing;
fbCalibCO  : FB_Sensor_Calibration_Processor;
L_CO_Processed : REAL;
L_CO_Raw_Word : WORD;

""",
    text,
    count=1,
    flags=re.MULTILINE,
)

# If fbCalibCO still missing, inject after fbSensorCO
if "fbCalibCO" not in text:
    text = text.replace(
        "fbSensorCO : FB_Sensor_Analog_Processing;",
        "fbSensorCO : FB_Sensor_Analog_Processing;\nfbCalibCO  : FB_Sensor_Calibration_Processor;",
        1,
    )

if "L_CO_Raw_Word : WORD;" not in text:
    text = text.replace(
        "L_CO_Processed : REAL;",
        "L_CO_Processed : REAL;\nL_CO_Raw_Word : WORD;",
        1,
    )

# 2.2 Replace call block robustly
shadow_call_pattern = re.compile(
    r"// === SENSOR PROCESSING \(SHADOW\) ===\n"
    r"(?P<body>.*?)"
    r"\n// === LIFETIME UPDATE ===",
    re.DOTALL
)

replacement_block = """// === SENSOR PROCESSING (SHADOW) ===
L_CO_Raw_Word := REAL_TO_WORD(GVL_STATE.G_CO_Sensors[1]);
GVL_Sensor_Shadow.G_CO_Raw_Word := L_CO_Raw_Word;

fbSensorCO(
    VI_Raw_Value := L_CO_Raw_Word,
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

GVL_Sensor_Shadow.G_CO_Processed := L_CO_Processed;
GVL_Sensor_Shadow.G_CO_Calibrated := fbCalibCO.VO_Calibrated_Value;
GVL_Sensor_Shadow.G_CO_Error := fbSensorCO.VO_Error;
GVL_Sensor_Shadow.G_CO_Diag_Code := fbSensorCO.VO_Diag_Code;

// === LIFETIME UPDATE ==="""

if not shadow_call_pattern.search(text):
    raise SystemExit("Shadow call region not found before lifetime block in PRG_System.st")

text = shadow_call_pattern.sub(replacement_block, text, count=1)

prg_path.write_text(text, encoding="utf-8")
print("OK: robust shadow CO pipeline applied")
