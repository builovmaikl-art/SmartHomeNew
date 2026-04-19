from pathlib import Path

# ------------------------------------------------------------
# 1) Extend diagnostics
# ------------------------------------------------------------
dut = Path("ST_System_Diagnostics.dut")
dut_text = dut.read_text(encoding="utf-8")

anchor = "    Calibration_OutdoorTemp_Summary_Text : STRING(160);\n\n\n\nEND_STRUCT"
insert = """    Calibration_OutdoorTemp_Summary_Text : STRING(160);

    // === HUMIDITY FAMILY PILOT ===
    Calibration_RoomHum1_Active : BOOL;
    Calibration_RoomHum1_Calibrated_Value : REAL;
    Calibration_RoomHum1_Summary_Text : STRING(160);



END_STRUCT"""

if "Calibration_RoomHum1_Active : BOOL;" not in dut_text:
    if anchor not in dut_text:
        raise SystemExit("Diagnostics anchor not found in ST_System_Diagnostics.dut")
    dut_text = dut_text.replace(anchor, insert, 1)

dut.write_text(dut_text, encoding="utf-8")

# ------------------------------------------------------------
# 2) Extend PRG_System VAR
# ------------------------------------------------------------
prg = Path("PRG_System.st")
prg_text = prg.read_text(encoding="utf-8")

fb_anchor = "fbCalibVerifyOutdoorTemp : FB_Calibration_Manager;"
fb_insert = """fbCalibVerifyOutdoorTemp : FB_Calibration_Manager;
fbCalibRoomHum1 : FB_Sensor_Calibration_Processor;"""

if "fbCalibRoomHum1 : FB_Sensor_Calibration_Processor;" not in prg_text:
    if fb_anchor not in prg_text:
        raise SystemExit("FB anchor not found in PRG_System.st")
    prg_text = prg_text.replace(fb_anchor, fb_insert, 1)

val_anchor = "L_OutdoorTemp_Calibrated : REAL;"
val_insert = """L_OutdoorTemp_Calibrated : REAL;
L_RoomHum1_Calibrated : REAL;"""

if "L_RoomHum1_Calibrated : REAL;" not in prg_text:
    if val_anchor not in prg_text:
        raise SystemExit("Value var anchor not found in PRG_System.st")
    prg_text = prg_text.replace(val_anchor, val_insert, 1)

# ------------------------------------------------------------
# 3) Insert humidity pilot right after outdoor temp generic family block
# ------------------------------------------------------------
anchor_block = """END_FOR;

// === SMOKE SHADOW EXEC ===
"""

new_block = """END_FOR;

// === HUMIDITY FAMILY PILOT ===
// NOTE:
// FB_Calibration_Manager currently supports only:
//   1 = Temp, 2 = Pressure, 3 = Gas
// Therefore this pilot integrates calibration/export first,
// without fake verification semantics for humidity.
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

if "// === HUMIDITY FAMILY PILOT ===" not in prg_text:
    if anchor_block not in prg_text:
        raise SystemExit("Humidity insertion anchor block not found in PRG_System.st")
    prg_text = prg_text.replace(anchor_block, new_block, 1)

prg.write_text(prg_text, encoding="utf-8")
print("OK: humidity family pilot integrated")
