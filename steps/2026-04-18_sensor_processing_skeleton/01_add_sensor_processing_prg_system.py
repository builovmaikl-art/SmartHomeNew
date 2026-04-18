from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

# === VAR BLOCK ===
var_block = """
// === SENSOR PROCESSING (SHADOW) ===
fbSensorCO : FB_Sensor_Analog_Processing;
L_CO_Processed : REAL;
"""

if "fbSensorCO" not in text:
    text = text.replace("VAR", "VAR\n" + var_block, 1)

# === CALL BLOCK ===
call_block = """
// === SENSOR PROCESSING (SHADOW) ===
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

if "// === SENSOR PROCESSING (SHADOW) ===" not in text:
    marker = "// === TREND → HISTORY WRITE"
    text = text.replace(marker, call_block + "\n" + marker, 1)

path.write_text(text, encoding="utf-8")
print("OK: sensor processing skeleton added")
