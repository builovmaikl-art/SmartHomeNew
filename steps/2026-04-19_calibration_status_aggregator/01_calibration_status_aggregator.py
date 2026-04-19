from pathlib import Path

# ------------------------------------------------------------
# 1) Extend diagnostics
# ------------------------------------------------------------
dut = Path("ST_System_Diagnostics.dut")
dut_text = dut.read_text(encoding="utf-8")

agg_block = """    // === CALIBRATION STATUS AGGREGATOR ===
    Calibration_Status_Global : INT;
    Calibration_Status_Gas : INT;
    Calibration_Status_Temperature : INT;
    Calibration_Status_Pressure : INT;
    Calibration_Status_Humidity : INT;
    Calibration_Status_Summary_Text : STRING(160);

"""

if "Calibration_Status_Global : INT;" not in dut_text:
    marker = "\nEND_STRUCT\nEND_TYPE"
    if marker not in dut_text:
        raise SystemExit("END_STRUCT marker not found in ST_System_Diagnostics.dut")
    dut_text = dut_text.replace(marker, "\n" + agg_block + "END_STRUCT\nEND_TYPE", 1)

dut.write_text(dut_text, encoding="utf-8")

# ------------------------------------------------------------
# 2) Insert aggregator block into PRG_System after pressure/humidity family blocks
# ------------------------------------------------------------
prg = Path("PRG_System.st")
text = prg.read_text(encoding="utf-8")

old = """END_FOR;
// === SMOKE SHADOW EXEC ===
"""

new = """END_FOR;

// === CALIBRATION STATUS AGGREGATOR ===
// Status codes:
// 0 = OK
// 1 = IN_PROGRESS
// 2 = WARNING
// 3 = ERROR

// Gas family
IF GVL_STATUS.G_Diagnostics.Calibration_CO_Verification_Failed OR
   GVL_STATUS.G_Diagnostics.Calibration_Methane_Verification_Failed THEN
    GVL_STATUS.G_Diagnostics.Calibration_Status_Gas := 3;
ELSIF GVL_STATUS.G_Diagnostics.Calibration_CO_Verification_Active OR
      GVL_STATUS.G_Diagnostics.Calibration_Methane_Verification_Active THEN
    GVL_STATUS.G_Diagnostics.Calibration_Status_Gas := 1;
ELSIF (GVL_STATUS.G_Diagnostics.Calibration_CO_Deviation_Percent > 2.0) OR
      (GVL_STATUS.G_Diagnostics.Calibration_Methane_Deviation_Percent > 2.0) THEN
    GVL_STATUS.G_Diagnostics.Calibration_Status_Gas := 2;
ELSE
    GVL_STATUS.G_Diagnostics.Calibration_Status_Gas := 0;
END_IF;

// Temperature family
IF GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Verification_Failed OR
   GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Verification_Failed OR
   GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Verification_Failed THEN
    GVL_STATUS.G_Diagnostics.Calibration_Status_Temperature := 3;
ELSIF GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Verification_Active OR
      GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Verification_Active OR
      GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Verification_Active THEN
    GVL_STATUS.G_Diagnostics.Calibration_Status_Temperature := 1;
ELSIF (GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Deviation_Percent > 2.0) OR
      (GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Deviation_Percent > 2.0) OR
      (GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Deviation_Percent > 2.0) THEN
    GVL_STATUS.G_Diagnostics.Calibration_Status_Temperature := 2;
ELSE
    GVL_STATUS.G_Diagnostics.Calibration_Status_Temperature := 0;
END_IF;

// Pressure family
IF GVL_STATUS.G_Diagnostics.Calibration_DHWPressure_Verification_Failed THEN
    GVL_STATUS.G_Diagnostics.Calibration_Status_Pressure := 3;
ELSIF GVL_STATUS.G_Diagnostics.Calibration_DHWPressure_Verification_Active THEN
    GVL_STATUS.G_Diagnostics.Calibration_Status_Pressure := 1;
ELSIF GVL_STATUS.G_Diagnostics.Calibration_DHWPressure_Deviation_Percent > 2.0 THEN
    GVL_STATUS.G_Diagnostics.Calibration_Status_Pressure := 2;
ELSE
    GVL_STATUS.G_Diagnostics.Calibration_Status_Pressure := 0;
END_IF;

// Humidity family
IF GVL_STATUS.G_Diagnostics.Calibration_RoomHum1_Active THEN
    GVL_STATUS.G_Diagnostics.Calibration_Status_Humidity := 0;
ELSE
    GVL_STATUS.G_Diagnostics.Calibration_Status_Humidity := 2;
END_IF;

// Global
GVL_STATUS.G_Diagnostics.Calibration_Status_Global := 0;

IF GVL_STATUS.G_Diagnostics.Calibration_Status_Humidity > GVL_STATUS.G_Diagnostics.Calibration_Status_Global THEN
    GVL_STATUS.G_Diagnostics.Calibration_Status_Global := GVL_STATUS.G_Diagnostics.Calibration_Status_Humidity;
END_IF;

IF GVL_STATUS.G_Diagnostics.Calibration_Status_Pressure > GVL_STATUS.G_Diagnostics.Calibration_Status_Global THEN
    GVL_STATUS.G_Diagnostics.Calibration_Status_Global := GVL_STATUS.G_Diagnostics.Calibration_Status_Pressure;
END_IF;

IF GVL_STATUS.G_Diagnostics.Calibration_Status_Temperature > GVL_STATUS.G_Diagnostics.Calibration_Status_Global THEN
    GVL_STATUS.G_Diagnostics.Calibration_Status_Global := GVL_STATUS.G_Diagnostics.Calibration_Status_Temperature;
END_IF;

IF GVL_STATUS.G_Diagnostics.Calibration_Status_Gas > GVL_STATUS.G_Diagnostics.Calibration_Status_Global THEN
    GVL_STATUS.G_Diagnostics.Calibration_Status_Global := GVL_STATUS.G_Diagnostics.Calibration_Status_Gas;
END_IF;

CASE GVL_STATUS.G_Diagnostics.Calibration_Status_Global OF
    3:
        GVL_STATUS.G_Diagnostics.Calibration_Status_Summary_Text := 'Calibration status: ERROR';
    2:
        GVL_STATUS.G_Diagnostics.Calibration_Status_Summary_Text := 'Calibration status: WARNING';
    1:
        GVL_STATUS.G_Diagnostics.Calibration_Status_Summary_Text := 'Calibration status: IN_PROGRESS';
ELSE
    GVL_STATUS.G_Diagnostics.Calibration_Status_Summary_Text := 'Calibration status: OK';
END_CASE;

// === SMOKE SHADOW EXEC ===
"""

if "// === CALIBRATION STATUS AGGREGATOR ===" not in text:
    if old not in text:
        raise SystemExit("Exact insertion point before smoke section not found")
    text = text.replace(old, new, 1)

prg.write_text(text, encoding="utf-8")
print("OK: calibration status aggregator integrated")
