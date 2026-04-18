from pathlib import Path
import subprocess
import re

# ------------------------------------------------------------
# 1) Restore PRG_System.st from previous commit (known green)
# ------------------------------------------------------------
prev = subprocess.check_output(
    ["git", "show", "HEAD~1:PRG_System.st"],
    text=True,
    encoding="utf-8"
)
Path("PRG_System.st").write_text(prev, encoding="utf-8")

# ------------------------------------------------------------
# 2) Create / overwrite GVL_Sensor_Shadow.gvl
# ------------------------------------------------------------
Path("GVL_Sensor_Shadow.gvl").write_text(
"""VAR_GLOBAL
    // === CO SHADOW PIPELINE ===
    G_CO_Raw_Word : WORD;
    G_CO_Processed : REAL;
    G_CO_Calibrated : REAL;
    G_CO_Error : BOOL;
    G_CO_Diag_Code : WORD;
END_VAR
""",
    encoding="utf-8"
)

# ------------------------------------------------------------
# 3) Re-open restored PRG_System.st and patch safely
# ------------------------------------------------------------
path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

# 3.1 Extend existing shadow VAR block
old_var = """// === SENSOR PROCESSING (SHADOW) ===
fbSensorCO : FB_Sensor_Analog_Processing;
L_CO_Processed : REAL;
"""

new_var = """// === SENSOR PROCESSING (SHADOW) ===
fbSensorCO : FB_Sensor_Analog_Processing;
fbCalibCO  : FB_Sensor_Calibration_Processor;
L_CO_Processed : REAL;
L_CO_Raw_Word : WORD;
"""

if old_var not in text:
    raise SystemExit("Expected restored shadow VAR block not found")

text = text.replace(old_var, new_var, 1)

# 3.2 Replace existing simple shadow call block
old_call = """// === SENSOR PROCESSING (SHADOW) ===
fbSensorCO(
    VI_Raw_Value := REAL_TO_WORD(GVL_STATE.G_CO_Sensors[1]),
    VI_Sensor_Type := 0,
    VI_Min_Scale := 0.0,
    VI_Max_Scale := 100.0,
    VI_Offset := 0.0,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

L_CO_Processed := fbSensorCO.VO_Value;
"""

new_call = """// === SENSOR PROCESSING (SHADOW) ===
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
"""

if old_call not in text:
    raise SystemExit("Expected restored simple shadow call block not found")

text = text.replace(old_call, new_call, 1)

path.write_text(text, encoding="utf-8")
print("OK: restored PRG_System from HEAD~1 and safely reapplied shadow CO pipeline")
