from pathlib import Path

prg = Path("PRG_System.st")
text = prg.read_text(encoding="utf-8")

# ------------------------------------------------------------
# 1) Replace scalar FB with array
# ------------------------------------------------------------
old_fb = "fbCalibRoomHum1 : FB_Sensor_Calibration_Processor;"
new_fb = "fbCalibHumidityFamily : ARRAY[1..1] OF FB_Sensor_Calibration_Processor;"

if old_fb not in text:
    raise SystemExit("Humidity FB not found")

text = text.replace(old_fb, new_fb, 1)

# ------------------------------------------------------------
# 2) Replace scalar var with family vars
# ------------------------------------------------------------
old_val = "L_RoomHum1_Calibrated : REAL;"
new_val = """L_RoomHum1_Calibrated : REAL;
L_HumidityFamily_Raw : REAL;
L_HumidityFamily_Calibrated : ARRAY[1..1] OF REAL;"""

text = text.replace(old_val, new_val, 1)

# add index
if "L_HumidityFamily_i : INT;" not in text:
    anchor = "L_PressureFamily_i : INT;"
    text = text.replace(anchor, anchor + "\n    L_HumidityFamily_i : INT;", 1)

# ------------------------------------------------------------
# 3) Replace pilot block with generic loop
# ------------------------------------------------------------
start_marker = "// === HUMIDITY FAMILY PILOT ==="
end_marker = "// === SMOKE SHADOW EXEC ==="

if start_marker not in text:
    raise SystemExit("Humidity pilot block not found")

start = text.index(start_marker)
end = text.index(end_marker, start)

new_block = """// === HUMIDITY FAMILY GENERIC LOOP ===
// Mapping:
// 1 -> RoomHum1 (record[6])
FOR L_HumidityFamily_i := 1 TO 1 DO

    L_HumidityFamily_Raw := GVL_STATE.G_Room_Hum[1];

    fbCalibHumidityFamily[L_HumidityFamily_i](
        VI_Raw_Value := L_HumidityFamily_Raw,
        VI_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[6]
    );

    L_HumidityFamily_Calibrated[L_HumidityFamily_i] :=
        fbCalibHumidityFamily[L_HumidityFamily_i].VO_Calibrated_Value;

    L_RoomHum1_Calibrated := L_HumidityFamily_Calibrated[1];

    GVL_STATUS.G_Diagnostics.Calibration_RoomHum1_Active := TRUE;
    GVL_STATUS.G_Diagnostics.Calibration_RoomHum1_Calibrated_Value := L_RoomHum1_Calibrated;
    GVL_STATUS.G_Diagnostics.Calibration_RoomHum1_Summary_Text :=
        'RoomHum1 calibration (generic loop)';

END_FOR;
"""

text = text[:start] + new_block + text[end:]

prg.write_text(text, encoding="utf-8")
print("OK: humidity family generic scaffolding integrated")
