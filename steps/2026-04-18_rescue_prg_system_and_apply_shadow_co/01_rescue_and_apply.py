from pathlib import Path
import subprocess
import sys

def sh(*args: str) -> str:
    return subprocess.check_output(list(args), text=True, encoding="utf-8")

# ------------------------------------------------------------
# 1) Find last good commit for PRG_System.st:
#    prefer the step-198 skeleton commit, otherwise latest commit
#    touching PRG_System before any shadow-CO rescue attempts
# ------------------------------------------------------------
log_lines = sh("git", "log", "--format=%H\t%s", "--", "PRG_System.st").splitlines()

restore_commit = None

# First preference: exact skeleton commit
for line in log_lines:
    parts = line.split("\t", 1)
    if len(parts) != 2:
        continue
    commit, subj = parts
    subj_low = subj.lower()
    if "sensor processing skeleton" in subj_low:
        restore_commit = commit
        break

# Fallback: latest PRG_System commit before shadow-co attempts
if restore_commit is None:
    banned = (
        "shadow co pipeline",
        "shadow_co_pipeline",
        "restore prg_system",
        "rescue prg_system",
        "robust shadow co",
    )
    for line in log_lines:
        parts = line.split("\t", 1)
        if len(parts) != 2:
            continue
        commit, subj = parts
        subj_low = subj.lower()
        if any(x in subj_low for x in banned):
            continue
        restore_commit = commit
        break

if restore_commit is None:
    raise SystemExit("Could not determine restore commit for PRG_System.st")

restored = sh("git", "show", f"{restore_commit}:PRG_System.st")
Path("PRG_System.st").write_text(restored, encoding="utf-8")

# ------------------------------------------------------------
# 2) Recreate shadow GVL
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
# 3) Safely patch restored PRG_System.st
# ------------------------------------------------------------
path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

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
    raise SystemExit("Expected step-198 shadow VAR block not found after restore")

text = text.replace(old_var, new_var, 1)

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
    raise SystemExit("Expected step-198 simple shadow call block not found after restore")

text = text.replace(old_call, new_call, 1)

path.write_text(text, encoding="utf-8")

print(f"OK: restore_commit={restore_commit}")
print("OK: PRG_System restored and shadow CO pipeline safely applied")
