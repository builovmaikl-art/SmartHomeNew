from pathlib import Path
import subprocess
import sys

def sh(*args):
    return subprocess.check_output(list(args), text=True, encoding="utf-8")

# ------------------------------------------------------------
# 1) Find exact step-198 commit
# ------------------------------------------------------------
log = sh("git", "log", "--format=%H\t%s", "--all", "--", "PRG_System.st").splitlines()

restore_commit = None
for line in log:
    if "\t" not in line:
        continue
    commit, subj = line.split("\t", 1)
    if subj.strip().lower() == "feat: add sensor processing skeleton (shadow mode)":
        restore_commit = commit
        break

if restore_commit is None:
    print("ERROR: step-198 commit not found", file=sys.stderr)
    sys.exit(2)

# ------------------------------------------------------------
# 2) Restore PRG_System.st exactly from step-198 commit
# ------------------------------------------------------------
restored = sh("git", "show", f"{restore_commit}:PRG_System.st")
Path("PRG_System.st").write_text(restored, encoding="utf-8")

# sanity check
text = Path("PRG_System.st").read_text(encoding="utf-8")
expected_var = """// === SENSOR PROCESSING (SHADOW) ===
fbSensorCO : FB_Sensor_Analog_Processing;
L_CO_Processed : REAL;
"""
expected_call = """// === SENSOR PROCESSING (SHADOW) ===
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

if expected_var not in text:
    print("ERROR: restored PRG_System does not contain expected step-198 shadow VAR block", file=sys.stderr)
    sys.exit(3)

if expected_call not in text:
    print("ERROR: restored PRG_System does not contain expected step-198 shadow call block", file=sys.stderr)
    sys.exit(4)

# ------------------------------------------------------------
# 3) Create GVL_Sensor_Shadow.gvl
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
# 4) Patch VAR block
# ------------------------------------------------------------
new_var = """// === SENSOR PROCESSING (SHADOW) ===
fbSensorCO : FB_Sensor_Analog_Processing;
fbCalibCO  : FB_Sensor_Calibration_Processor;
L_CO_Processed : REAL;
L_CO_Raw_Word : WORD;
"""
text = text.replace(expected_var, new_var, 1)

# ------------------------------------------------------------
# 5) Patch shadow call block
# ------------------------------------------------------------
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
text = text.replace(expected_call, new_call, 1)

Path("PRG_System.st").write_text(text, encoding="utf-8")

print(f"OK: restore_commit={restore_commit}")
print("OK: PRG_System restored from step-198 and shadow CO pipeline applied")
