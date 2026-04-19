from pathlib import Path

prg = Path("PRG_System.st")
text = prg.read_text(encoding="utf-8")

# ------------------------------------------------------------
# 1) Add local mapping arrays/const-like vars in VAR section
# ------------------------------------------------------------
anchor = "L_HumidityFamily_i : INT;"
insert = """L_HumidityFamily_i : INT;
    // === CALIBRATION CONFIG-DRIVEN MAPPING (STAGE 1) ===
    L_GasFamily_Record_Index : ARRAY[1..2] OF INT := [1, 2];
    L_TempFamily_Record_Index : ARRAY[1..3] OF INT := [3, 4, 5];
    L_PressureFamily_Record_Index : ARRAY[1..1] OF INT := [7];
    L_HumidityFamily_Record_Index : ARRAY[1..1] OF INT := [6];"""

if "L_GasFamily_Record_Index : ARRAY[1..2] OF INT := [1, 2];" not in text:
    if anchor not in text:
        raise SystemExit("Mapping anchor not found")
    text = text.replace(anchor, insert, 1)

# ------------------------------------------------------------
# 2) Gas family: replace hardcoded record indexes with mapping array
# ------------------------------------------------------------
text = text.replace(
    "VI_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[L_GasFamily_i]",
    "VI_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[L_GasFamily_Record_Index[L_GasFamily_i]]"
)

text = text.replace(
    "VI_Calib_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[L_GasFamily_i],",
    "VI_Calib_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[L_GasFamily_Record_Index[L_GasFamily_i]],"
)

text = text.replace(
    "GVL_CONFIG.G_HMI_Sensor_Calibrations[L_GasFamily_i].last_calibration_timestamp <> 0 AND",
    "GVL_CONFIG.G_HMI_Sensor_Calibrations[L_GasFamily_Record_Index[L_GasFamily_i]].last_calibration_timestamp <> 0 AND"
)

text = text.replace(
    "GVL_CONFIG.G_HMI_Sensor_Calibrations[L_GasFamily_i].last_calibration_timestamp <> L_GasFamily_Calib_TS_Prev[L_GasFamily_i]",
    "GVL_CONFIG.G_HMI_Sensor_Calibrations[L_GasFamily_Record_Index[L_GasFamily_i]].last_calibration_timestamp <> L_GasFamily_Calib_TS_Prev[L_GasFamily_i]"
)

text = text.replace(
    "GVL_CONFIG.G_HMI_Sensor_Calibrations[L_GasFamily_i].verification_passed :=",
    "GVL_CONFIG.G_HMI_Sensor_Calibrations[L_GasFamily_Record_Index[L_GasFamily_i]].verification_passed :="
)

text = text.replace(
    "L_GasFamily_Calib_TS_Prev[L_GasFamily_i] := GVL_CONFIG.G_HMI_Sensor_Calibrations[L_GasFamily_i].last_calibration_timestamp;",
    "L_GasFamily_Calib_TS_Prev[L_GasFamily_i] := GVL_CONFIG.G_HMI_Sensor_Calibrations[L_GasFamily_Record_Index[L_GasFamily_i]].last_calibration_timestamp;"
)

# ------------------------------------------------------------
# 3) Temp family: replace hardcoded +2 with mapping array
# ------------------------------------------------------------
text = text.replace(
    "VI_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[L_TempFamily_i + 2]",
    "VI_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[L_TempFamily_Record_Index[L_TempFamily_i]]"
)

text = text.replace(
    "VI_Calib_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[L_TempFamily_i + 2],",
    "VI_Calib_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[L_TempFamily_Record_Index[L_TempFamily_i]],"
)

text = text.replace(
    "GVL_CONFIG.G_HMI_Sensor_Calibrations[L_TempFamily_i + 2].last_calibration_timestamp <> 0 AND",
    "GVL_CONFIG.G_HMI_Sensor_Calibrations[L_TempFamily_Record_Index[L_TempFamily_i]].last_calibration_timestamp <> 0 AND"
)

text = text.replace(
    "GVL_CONFIG.G_HMI_Sensor_Calibrations[L_TempFamily_i + 2].last_calibration_timestamp <> L_TempFamily_Calib_TS_Prev[L_TempFamily_i]",
    "GVL_CONFIG.G_HMI_Sensor_Calibrations[L_TempFamily_Record_Index[L_TempFamily_i]].last_calibration_timestamp <> L_TempFamily_Calib_TS_Prev[L_TempFamily_i]"
)

text = text.replace(
    "GVL_CONFIG.G_HMI_Sensor_Calibrations[L_TempFamily_i + 2].verification_passed :=",
    "GVL_CONFIG.G_HMI_Sensor_Calibrations[L_TempFamily_Record_Index[L_TempFamily_i]].verification_passed :="
)

text = text.replace(
    "L_TempFamily_Calib_TS_Prev[L_TempFamily_i] := GVL_CONFIG.G_HMI_Sensor_Calibrations[L_TempFamily_i + 2].last_calibration_timestamp;",
    "L_TempFamily_Calib_TS_Prev[L_TempFamily_i] := GVL_CONFIG.G_HMI_Sensor_Calibrations[L_TempFamily_Record_Index[L_TempFamily_i]].last_calibration_timestamp;"
)

# ------------------------------------------------------------
# 4) Pressure family: replace hardcoded [7]
# ------------------------------------------------------------
text = text.replace(
    "VI_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[7]",
    "VI_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[L_PressureFamily_Record_Index[L_PressureFamily_i]]"
)

text = text.replace(
    "VI_Calib_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[7],",
    "VI_Calib_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[L_PressureFamily_Record_Index[L_PressureFamily_i]],"
)

text = text.replace(
    "GVL_CONFIG.G_HMI_Sensor_Calibrations[7].last_calibration_timestamp <> 0 AND",
    "GVL_CONFIG.G_HMI_Sensor_Calibrations[L_PressureFamily_Record_Index[L_PressureFamily_i]].last_calibration_timestamp <> 0 AND"
)

text = text.replace(
    "GVL_CONFIG.G_HMI_Sensor_Calibrations[7].last_calibration_timestamp <> L_PressureFamily_Calib_TS_Prev[1]",
    "GVL_CONFIG.G_HMI_Sensor_Calibrations[L_PressureFamily_Record_Index[L_PressureFamily_i]].last_calibration_timestamp <> L_PressureFamily_Calib_TS_Prev[1]"
)

text = text.replace(
    "GVL_CONFIG.G_HMI_Sensor_Calibrations[7].verification_passed :=",
    "GVL_CONFIG.G_HMI_Sensor_Calibrations[L_PressureFamily_Record_Index[L_PressureFamily_i]].verification_passed :="
)

text = text.replace(
    "L_PressureFamily_Calib_TS_Prev[1] :=\n        GVL_CONFIG.G_HMI_Sensor_Calibrations[7].last_calibration_timestamp;",
    "L_PressureFamily_Calib_TS_Prev[1] :=\n        GVL_CONFIG.G_HMI_Sensor_Calibrations[L_PressureFamily_Record_Index[L_PressureFamily_i]].last_calibration_timestamp;"
)

# ------------------------------------------------------------
# 5) Humidity family: replace hardcoded [6]
# ------------------------------------------------------------
text = text.replace(
    "VI_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[6]",
    "VI_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[L_HumidityFamily_Record_Index[L_HumidityFamily_i]]"
)

# ------------------------------------------------------------
# 6) Add stage-1 marker comment above first family
# ------------------------------------------------------------
marker = "// === GAS FAMILY CALIBRATION GENERIC LOOP ==="
if "// === CALIBRATION CONFIG-DRIVEN MAPPING STAGE 1 ===" not in text:
    if marker not in text:
        raise SystemExit("Gas family marker not found")
    text = text.replace(
        marker,
        "// === CALIBRATION CONFIG-DRIVEN MAPPING STAGE 1 ===\n" + marker,
        1
    )

prg.write_text(text, encoding="utf-8")
print("OK: config-driven mapping stage 1 integrated")
