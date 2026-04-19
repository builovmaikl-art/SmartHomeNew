from pathlib import Path

prg = Path("PRG_System.st")
text = prg.read_text(encoding="utf-8")

# 1) add FB declaration
fb_anchor = "fbCalibVerifyTempFamily : ARRAY[1..3] OF FB_Calibration_Manager;"
if "fbCalibRoomHum1 : FB_Sensor_Calibration_Processor;" not in text:
    if fb_anchor not in text:
        raise SystemExit("FB anchor not found")
    text = text.replace(
        fb_anchor,
        fb_anchor + "\nfbCalibRoomHum1 : FB_Sensor_Calibration_Processor;",
        1
    )

# 2) add calibrated value var
val_anchor = "L_OutdoorTemp_Calibrated : REAL;"
if "L_RoomHum1_Calibrated : REAL;" not in text:
    if val_anchor not in text:
        raise SystemExit("Value anchor not found")
    text = text.replace(
        val_anchor,
        val_anchor + "\nL_RoomHum1_Calibrated : REAL;",
        1
    )

# 3) insert humidity pilot exactly between temp-family END_FOR and smoke section
old = """END_FOR;

// === SMOKE SHADOW EXEC ===
"""
new = """END_FOR;

// === HUMIDITY FAMILY PILOT ===
// NOTE:
// FB_Calibration_Manager currently supports only:
//   1 = Temp, 2 = Pressure, 3 = Gas
// Therefore humidity is added first as calibration/export pilot,
// without fake verification semantics.
fbCalibRoomHum1(
    VI_Raw_Value := GVL_STATE.G_Room_Hum[1],
    VI_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[6]
);
L_RoomHum1_Calibrated := fbCalibRoomHum1.VO_Calibrated_Value;

GVL_STATUS.G_Diagnostics.Calibration_RoomHum1_Active := TRUE;
GVL_STATUS.G_Diagnostics.Calibration_RoomHum1_Calibrated_Value := L_RoomHum1_Calibrated;
GVL_STATUS.G_Diagnostics.Calibration_RoomHum1_Summary_Text := 'RoomHum1 calibration pilot active';

// === SMOKE SHADOW EXEC ===
"""

if "// === HUMIDITY FAMILY PILOT ===" not in text:
    if old not in text:
        raise SystemExit("Exact insertion point before smoke section not found")
    text = text.replace(old, new, 1)

prg.write_text(text, encoding="utf-8")
print("OK: precise humidity pilot repair applied")
