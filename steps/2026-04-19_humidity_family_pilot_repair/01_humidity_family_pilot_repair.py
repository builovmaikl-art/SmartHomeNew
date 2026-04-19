from pathlib import Path
import re

# ------------------------------------------------------------
# 1) ST_System_Diagnostics.dut: append humidity block before END_STRUCT
# ------------------------------------------------------------
dut = Path("ST_System_Diagnostics.dut")
dut_text = dut.read_text(encoding="utf-8")

humidity_dut_block = """    // === HUMIDITY FAMILY PILOT ===
    Calibration_RoomHum1_Active : BOOL;
    Calibration_RoomHum1_Calibrated_Value : REAL;
    Calibration_RoomHum1_Summary_Text : STRING(160);

"""

if "Calibration_RoomHum1_Active : BOOL;" not in dut_text:
    marker = "\nEND_STRUCT\nEND_TYPE"
    if marker not in dut_text:
        raise SystemExit("END_STRUCT marker not found in ST_System_Diagnostics.dut")
    dut_text = dut_text.replace(marker, "\n" + humidity_dut_block + "END_STRUCT\nEND_TYPE", 1)

dut.write_text(dut_text, encoding="utf-8")

# ------------------------------------------------------------
# 2) PRG_System.st: add FB + value var if missing
# ------------------------------------------------------------
prg = Path("PRG_System.st")
text = prg.read_text(encoding="utf-8")

fb_anchor = "fbCalibVerifyOutdoorTemp : FB_Calibration_Manager;"
if "fbCalibRoomHum1 : FB_Sensor_Calibration_Processor;" not in text:
    if fb_anchor not in text:
        raise SystemExit("FB anchor not found in PRG_System.st")
    text = text.replace(
        fb_anchor,
        fb_anchor + "\nfbCalibRoomHum1 : FB_Sensor_Calibration_Processor;",
        1
    )

val_anchor = "L_OutdoorTemp_Calibrated : REAL;"
if "L_RoomHum1_Calibrated : REAL;" not in text:
    if val_anchor not in text:
        raise SystemExit("Value var anchor not found in PRG_System.st")
    text = text.replace(
        val_anchor,
        val_anchor + "\nL_RoomHum1_Calibrated : REAL;",
        1
    )

# ------------------------------------------------------------
# 3) Insert humidity pilot after temperature-family generic loop
# ------------------------------------------------------------
humidity_block = """// === HUMIDITY FAMILY PILOT ===
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

"""

if "// === HUMIDITY FAMILY PILOT ===" not in text:
    m = re.search(
        r"// === TEMPERATURE FAMILY CALIBRATION GENERIC LOOP ===.*?END_FOR;\n",
        text,
        flags=re.DOTALL
    )
    if not m:
        raise SystemExit("Temperature family generic loop block not found")
    insert_at = m.end()
    text = text[:insert_at] + "\n" + humidity_block + text[insert_at:]

prg.write_text(text, encoding="utf-8")
print("OK: humidity family pilot repaired and integrated")
