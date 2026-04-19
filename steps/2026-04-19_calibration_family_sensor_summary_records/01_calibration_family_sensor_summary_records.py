from pathlib import Path

# ------------------------------------------------------------
# 1) Extend ST_System_Diagnostics with summary records
# ------------------------------------------------------------
dut = Path("ST_System_Diagnostics.dut")
dut_text = dut.read_text(encoding="utf-8")

summary_block = """    // === CALIBRATION FAMILY/SENSOR SUMMARY RECORDS ===
    Calibration_Family_Gas : ST_Calibration_Family_Summary;
    Calibration_Family_Temperature : ST_Calibration_Family_Summary;
    Calibration_Family_Pressure : ST_Calibration_Family_Summary;
    Calibration_Family_Humidity : ST_Calibration_Family_Summary;

    Calibration_Sensor_CO : ST_Calibration_Sensor_Summary;
    Calibration_Sensor_Methane : ST_Calibration_Sensor_Summary;
    Calibration_Sensor_FloorTemp1 : ST_Calibration_Sensor_Summary;
    Calibration_Sensor_FloorTemp2 : ST_Calibration_Sensor_Summary;
    Calibration_Sensor_OutdoorTemp : ST_Calibration_Sensor_Summary;
    Calibration_Sensor_RoomHum1 : ST_Calibration_Sensor_Summary;
    Calibration_Sensor_DHWPressure : ST_Calibration_Sensor_Summary;

"""

if "Calibration_Family_Gas : ST_Calibration_Family_Summary;" not in dut_text:
    marker = "\nEND_STRUCT\nEND_TYPE"
    if marker not in dut_text:
        raise SystemExit("END_STRUCT marker not found in ST_System_Diagnostics.dut")
    dut_text = dut_text.replace(marker, "\n" + summary_block + "END_STRUCT\nEND_TYPE", 1)

dut.write_text(dut_text, encoding="utf-8")

# ------------------------------------------------------------
# 2) Insert summary population block after calibration status aggregator
# ------------------------------------------------------------
prg = Path("PRG_System.st")
text = prg.read_text(encoding="utf-8")

old = """CASE GVL_STATUS.G_Diagnostics.Calibration_Status_Global OF
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

new = """CASE GVL_STATUS.G_Diagnostics.Calibration_Status_Global OF
    3:
        GVL_STATUS.G_Diagnostics.Calibration_Status_Summary_Text := 'Calibration status: ERROR';
    2:
        GVL_STATUS.G_Diagnostics.Calibration_Status_Summary_Text := 'Calibration status: WARNING';
    1:
        GVL_STATUS.G_Diagnostics.Calibration_Status_Summary_Text := 'Calibration status: IN_PROGRESS';
ELSE
    GVL_STATUS.G_Diagnostics.Calibration_Status_Summary_Text := 'Calibration status: OK';
END_CASE;

// === CALIBRATION FAMILY/SENSOR SUMMARY RECORDS ===
// Families
GVL_STATUS.G_Diagnostics.Calibration_Family_Gas.active := TRUE;
GVL_STATUS.G_Diagnostics.Calibration_Family_Gas.status := GVL_STATUS.G_Diagnostics.Calibration_Status_Gas;
GVL_STATUS.G_Diagnostics.Calibration_Family_Gas.sensor_count := 2;
GVL_STATUS.G_Diagnostics.Calibration_Family_Gas.verification_active_count := 0;
IF GVL_STATUS.G_Diagnostics.Calibration_CO_Verification_Active THEN
    GVL_STATUS.G_Diagnostics.Calibration_Family_Gas.verification_active_count :=
        GVL_STATUS.G_Diagnostics.Calibration_Family_Gas.verification_active_count + 1;
END_IF;
IF GVL_STATUS.G_Diagnostics.Calibration_Methane_Verification_Active THEN
    GVL_STATUS.G_Diagnostics.Calibration_Family_Gas.verification_active_count :=
        GVL_STATUS.G_Diagnostics.Calibration_Family_Gas.verification_active_count + 1;
END_IF;
GVL_STATUS.G_Diagnostics.Calibration_Family_Gas.failed_count := 0;
IF GVL_STATUS.G_Diagnostics.Calibration_CO_Verification_Failed THEN
    GVL_STATUS.G_Diagnostics.Calibration_Family_Gas.failed_count :=
        GVL_STATUS.G_Diagnostics.Calibration_Family_Gas.failed_count + 1;
END_IF;
IF GVL_STATUS.G_Diagnostics.Calibration_Methane_Verification_Failed THEN
    GVL_STATUS.G_Diagnostics.Calibration_Family_Gas.failed_count :=
        GVL_STATUS.G_Diagnostics.Calibration_Family_Gas.failed_count + 1;
END_IF;
GVL_STATUS.G_Diagnostics.Calibration_Family_Gas.max_deviation_percent := GVL_STATUS.G_Diagnostics.Calibration_CO_Deviation_Percent;
IF GVL_STATUS.G_Diagnostics.Calibration_Methane_Deviation_Percent >
   GVL_STATUS.G_Diagnostics.Calibration_Family_Gas.max_deviation_percent THEN
    GVL_STATUS.G_Diagnostics.Calibration_Family_Gas.max_deviation_percent :=
        GVL_STATUS.G_Diagnostics.Calibration_Methane_Deviation_Percent;
END_IF;
GVL_STATUS.G_Diagnostics.Calibration_Family_Gas.summary_text := 'Gas family';

GVL_STATUS.G_Diagnostics.Calibration_Family_Temperature.active := TRUE;
GVL_STATUS.G_Diagnostics.Calibration_Family_Temperature.status := GVL_STATUS.G_Diagnostics.Calibration_Status_Temperature;
GVL_STATUS.G_Diagnostics.Calibration_Family_Temperature.sensor_count := 3;
GVL_STATUS.G_Diagnostics.Calibration_Family_Temperature.verification_active_count := 0;
IF GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Verification_Active THEN
    GVL_STATUS.G_Diagnostics.Calibration_Family_Temperature.verification_active_count :=
        GVL_STATUS.G_Diagnostics.Calibration_Family_Temperature.verification_active_count + 1;
END_IF;
IF GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Verification_Active THEN
    GVL_STATUS.G_Diagnostics.Calibration_Family_Temperature.verification_active_count :=
        GVL_STATUS.G_Diagnostics.Calibration_Family_Temperature.verification_active_count + 1;
END_IF;
IF GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Verification_Active THEN
    GVL_STATUS.G_Diagnostics.Calibration_Family_Temperature.verification_active_count :=
        GVL_STATUS.G_Diagnostics.Calibration_Family_Temperature.verification_active_count + 1;
END_IF;
GVL_STATUS.G_Diagnostics.Calibration_Family_Temperature.failed_count := 0;
IF GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Verification_Failed THEN
    GVL_STATUS.G_Diagnostics.Calibration_Family_Temperature.failed_count :=
        GVL_STATUS.G_Diagnostics.Calibration_Family_Temperature.failed_count + 1;
END_IF;
IF GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Verification_Failed THEN
    GVL_STATUS.G_Diagnostics.Calibration_Family_Temperature.failed_count :=
        GVL_STATUS.G_Diagnostics.Calibration_Family_Temperature.failed_count + 1;
END_IF;
IF GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Verification_Failed THEN
    GVL_STATUS.G_Diagnostics.Calibration_Family_Temperature.failed_count :=
        GVL_STATUS.G_Diagnostics.Calibration_Family_Temperature.failed_count + 1;
END_IF;
GVL_STATUS.G_Diagnostics.Calibration_Family_Temperature.max_deviation_percent := GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Deviation_Percent;
IF GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Deviation_Percent >
   GVL_STATUS.G_Diagnostics.Calibration_Family_Temperature.max_deviation_percent THEN
    GVL_STATUS.G_Diagnostics.Calibration_Family_Temperature.max_deviation_percent :=
        GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Deviation_Percent;
END_IF;
IF GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Deviation_Percent >
   GVL_STATUS.G_Diagnostics.Calibration_Family_Temperature.max_deviation_percent THEN
    GVL_STATUS.G_Diagnostics.Calibration_Family_Temperature.max_deviation_percent :=
        GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Deviation_Percent;
END_IF;
GVL_STATUS.G_Diagnostics.Calibration_Family_Temperature.summary_text := 'Temperature family';

GVL_STATUS.G_Diagnostics.Calibration_Family_Pressure.active := TRUE;
GVL_STATUS.G_Diagnostics.Calibration_Family_Pressure.status := GVL_STATUS.G_Diagnostics.Calibration_Status_Pressure;
GVL_STATUS.G_Diagnostics.Calibration_Family_Pressure.sensor_count := 1;
GVL_STATUS.G_Diagnostics.Calibration_Family_Pressure.verification_active_count := 0;
IF GVL_STATUS.G_Diagnostics.Calibration_DHWPressure_Verification_Active THEN
    GVL_STATUS.G_Diagnostics.Calibration_Family_Pressure.verification_active_count := 1;
END_IF;
GVL_STATUS.G_Diagnostics.Calibration_Family_Pressure.failed_count := 0;
IF GVL_STATUS.G_Diagnostics.Calibration_DHWPressure_Verification_Failed THEN
    GVL_STATUS.G_Diagnostics.Calibration_Family_Pressure.failed_count := 1;
END_IF;
GVL_STATUS.G_Diagnostics.Calibration_Family_Pressure.max_deviation_percent := GVL_STATUS.G_Diagnostics.Calibration_DHWPressure_Deviation_Percent;
GVL_STATUS.G_Diagnostics.Calibration_Family_Pressure.summary_text := 'Pressure family';

GVL_STATUS.G_Diagnostics.Calibration_Family_Humidity.active := TRUE;
GVL_STATUS.G_Diagnostics.Calibration_Family_Humidity.status := GVL_STATUS.G_Diagnostics.Calibration_Status_Humidity;
GVL_STATUS.G_Diagnostics.Calibration_Family_Humidity.sensor_count := 1;
GVL_STATUS.G_Diagnostics.Calibration_Family_Humidity.verification_active_count := 0;
GVL_STATUS.G_Diagnostics.Calibration_Family_Humidity.failed_count := 0;
GVL_STATUS.G_Diagnostics.Calibration_Family_Humidity.max_deviation_percent := 0.0;
GVL_STATUS.G_Diagnostics.Calibration_Family_Humidity.summary_text := 'Humidity family';

// Sensors
GVL_STATUS.G_Diagnostics.Calibration_Sensor_CO.active := TRUE;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_CO.status := GVL_STATUS.G_Diagnostics.Calibration_Status_Gas;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_CO.calibrated_value := L_CO_Calibrated;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_CO.deviation_percent := GVL_STATUS.G_Diagnostics.Calibration_CO_Deviation_Percent;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_CO.verification_active := GVL_STATUS.G_Diagnostics.Calibration_CO_Verification_Active;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_CO.verification_failed := GVL_STATUS.G_Diagnostics.Calibration_CO_Verification_Failed;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_CO.record_index := 1;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_CO.label := 'CO';
GVL_STATUS.G_Diagnostics.Calibration_Sensor_CO.summary_text := 'CO sensor';

GVL_STATUS.G_Diagnostics.Calibration_Sensor_Methane.active := TRUE;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_Methane.status := GVL_STATUS.G_Diagnostics.Calibration_Status_Gas;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_Methane.calibrated_value := L_Methane_Calibrated;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_Methane.deviation_percent := GVL_STATUS.G_Diagnostics.Calibration_Methane_Deviation_Percent;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_Methane.verification_active := GVL_STATUS.G_Diagnostics.Calibration_Methane_Verification_Active;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_Methane.verification_failed := GVL_STATUS.G_Diagnostics.Calibration_Methane_Verification_Failed;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_Methane.record_index := 2;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_Methane.label := 'Methane';
GVL_STATUS.G_Diagnostics.Calibration_Sensor_Methane.summary_text := 'Methane sensor';

GVL_STATUS.G_Diagnostics.Calibration_Sensor_FloorTemp1.active := TRUE;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_FloorTemp1.status := GVL_STATUS.G_Diagnostics.Calibration_Status_Temperature;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_FloorTemp1.calibrated_value := L_FloorTemp1_Calibrated;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_FloorTemp1.deviation_percent := GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Deviation_Percent;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_FloorTemp1.verification_active := GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Verification_Active;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_FloorTemp1.verification_failed := GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Verification_Failed;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_FloorTemp1.record_index := 3;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_FloorTemp1.label := 'FloorTemp1';
GVL_STATUS.G_Diagnostics.Calibration_Sensor_FloorTemp1.summary_text := 'Floor temperature 1';

GVL_STATUS.G_Diagnostics.Calibration_Sensor_FloorTemp2.active := TRUE;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_FloorTemp2.status := GVL_STATUS.G_Diagnostics.Calibration_Status_Temperature;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_FloorTemp2.calibrated_value := L_FloorTemp2_Calibrated;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_FloorTemp2.deviation_percent := GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Deviation_Percent;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_FloorTemp2.verification_active := GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Verification_Active;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_FloorTemp2.verification_failed := GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Verification_Failed;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_FloorTemp2.record_index := 4;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_FloorTemp2.label := 'FloorTemp2';
GVL_STATUS.G_Diagnostics.Calibration_Sensor_FloorTemp2.summary_text := 'Floor temperature 2';

GVL_STATUS.G_Diagnostics.Calibration_Sensor_OutdoorTemp.active := TRUE;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_OutdoorTemp.status := GVL_STATUS.G_Diagnostics.Calibration_Status_Temperature;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_OutdoorTemp.calibrated_value := L_OutdoorTemp_Calibrated;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_OutdoorTemp.deviation_percent := GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Deviation_Percent;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_OutdoorTemp.verification_active := GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Verification_Active;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_OutdoorTemp.verification_failed := GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Verification_Failed;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_OutdoorTemp.record_index := 5;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_OutdoorTemp.label := 'OutdoorTemp';
GVL_STATUS.G_Diagnostics.Calibration_Sensor_OutdoorTemp.summary_text := 'Outdoor temperature';

GVL_STATUS.G_Diagnostics.Calibration_Sensor_RoomHum1.active := TRUE;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_RoomHum1.status := GVL_STATUS.G_Diagnostics.Calibration_Status_Humidity;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_RoomHum1.calibrated_value := L_RoomHum1_Calibrated;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_RoomHum1.deviation_percent := 0.0;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_RoomHum1.verification_active := FALSE;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_RoomHum1.verification_failed := FALSE;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_RoomHum1.record_index := 6;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_RoomHum1.label := 'RoomHum1';
GVL_STATUS.G_Diagnostics.Calibration_Sensor_RoomHum1.summary_text := 'Room humidity 1';

GVL_STATUS.G_Diagnostics.Calibration_Sensor_DHWPressure.active := TRUE;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_DHWPressure.status := GVL_STATUS.G_Diagnostics.Calibration_Status_Pressure;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_DHWPressure.calibrated_value := L_DHWPressure_Calibrated;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_DHWPressure.deviation_percent := GVL_STATUS.G_Diagnostics.Calibration_DHWPressure_Deviation_Percent;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_DHWPressure.verification_active := GVL_STATUS.G_Diagnostics.Calibration_DHWPressure_Verification_Active;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_DHWPressure.verification_failed := GVL_STATUS.G_Diagnostics.Calibration_DHWPressure_Verification_Failed;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_DHWPressure.record_index := 7;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_DHWPressure.label := 'DHWPressure';
GVL_STATUS.G_Diagnostics.Calibration_Sensor_DHWPressure.summary_text := 'DHW pressure';

// === SMOKE SHADOW EXEC ===
"""

if "// === CALIBRATION FAMILY/SENSOR SUMMARY RECORDS ===" not in text:
    if old not in text:
        raise SystemExit("Aggregator insertion anchor not found")
    text = text.replace(old, new, 1)

prg.write_text(text, encoding="utf-8")
print("OK: calibration family/sensor summary records integrated")
