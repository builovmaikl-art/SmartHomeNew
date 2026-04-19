from pathlib import Path

prg = Path("PRG_System.st")
text = prg.read_text(encoding="utf-8")

# ------------------------------------------------------------
# 1) Replace scalar FB declarations with array FB declarations
# ------------------------------------------------------------
old_fb = """fbCalibFloorTemp1 : FB_Sensor_Calibration_Processor;
fbCalibVerifyFloorTemp1 : FB_Calibration_Manager;
fbCalibFloorTemp2 : FB_Sensor_Calibration_Processor;
fbCalibVerifyFloorTemp2 : FB_Calibration_Manager;
fbCalibOutdoorTemp : FB_Sensor_Calibration_Processor;
fbCalibVerifyOutdoorTemp : FB_Calibration_Manager;"""

new_fb = """fbCalibTempFamily : ARRAY[1..3] OF FB_Sensor_Calibration_Processor;
fbCalibVerifyTempFamily : ARRAY[1..3] OF FB_Calibration_Manager;"""

if old_fb in text:
    text = text.replace(old_fb, new_fb, 1)

# ------------------------------------------------------------
# 2) Replace scalar temp vars with generic temp-family vars
# ------------------------------------------------------------
old_vals = """L_FloorTemp1_Calibrated : REAL;
L_FloorTemp2_Calibrated : REAL;
L_OutdoorTemp_Calibrated : REAL;"""

new_vals = """L_TempFamily_Raw : REAL;
L_TempFamily_Calibrated : ARRAY[1..3] OF REAL;"""

if old_vals in text:
    text = text.replace(old_vals, new_vals, 1)

old_prev = """L_FloorTemp1_Calib_TS_Prev : UDINT;
L_FloorTemp1_Verification_Active_Prev : BOOL;
L_FloorTemp2_Calib_TS_Prev : UDINT;
L_FloorTemp2_Verification_Active_Prev : BOOL;
L_OutdoorTemp_Calib_TS_Prev : UDINT;
L_OutdoorTemp_Verification_Active_Prev : BOOL;"""

new_prev = """L_TempFamily_Calib_TS_Prev : ARRAY[1..3] OF UDINT;
L_TempFamily_Verification_Active_Prev : ARRAY[1..3] OF BOOL;"""

if old_prev in text:
    text = text.replace(old_prev, new_prev, 1)

# ------------------------------------------------------------
# 3) Replace the three scalar observer blocks with one generic loop
# ------------------------------------------------------------
old_block = """// === FLOOR TEMP 1 CALIBRATION OBSERVER (PILOT) ===
fbCalibFloorTemp1(
    VI_Raw_Value := GVL_STATE.G_Floor_Temps[1],
    VI_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[3]
);
L_FloorTemp1_Calibrated := fbCalibFloorTemp1.VO_Calibrated_Value;

fbCalibVerifyFloorTemp1(
    VI_Raw_Value := GVL_STATE.G_Floor_Temps[1],
    VI_Type := 1,
    VI_Calib_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[3],
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Start_Verification := (
        GVL_CONFIG.G_HMI_Sensor_Calibrations[3].last_calibration_timestamp <> 0 AND
        GVL_CONFIG.G_HMI_Sensor_Calibrations[3].last_calibration_timestamp <> L_FloorTemp1_Calib_TS_Prev
    )
);

GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Active := TRUE;
GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Verification_Active :=
    fbCalibVerifyFloorTemp1.VO_Verification_Active;
GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Verification_Failed :=
    fbCalibVerifyFloorTemp1.VO_Verification_Failed;
GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Deviation_Percent :=
    fbCalibVerifyFloorTemp1.VO_Deviation_Percent;

IF GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Verification_Failed THEN
    GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Summary_Text := 'FloorTemp1 verification failed';
ELSIF GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Verification_Active THEN
    GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Summary_Text := 'FloorTemp1 verification active';
ELSE
    GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Summary_Text := 'FloorTemp1 verification idle';
END_IF;

IF L_FloorTemp1_Verification_Active_Prev AND
   (NOT fbCalibVerifyFloorTemp1.VO_Verification_Active) THEN
    GVL_CONFIG.G_HMI_Sensor_Calibrations[3].verification_passed :=
        NOT fbCalibVerifyFloorTemp1.VO_Verification_Failed;
END_IF;

L_FloorTemp1_Verification_Active_Prev := fbCalibVerifyFloorTemp1.VO_Verification_Active;
L_FloorTemp1_Calib_TS_Prev := GVL_CONFIG.G_HMI_Sensor_Calibrations[3].last_calibration_timestamp;

// === FLOOR TEMP 2 CALIBRATION OBSERVER ===
fbCalibFloorTemp2(
    VI_Raw_Value := GVL_STATE.G_Floor_Temps[2],
    VI_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[4]
);
L_FloorTemp2_Calibrated := fbCalibFloorTemp2.VO_Calibrated_Value;

fbCalibVerifyFloorTemp2(
    VI_Raw_Value := GVL_STATE.G_Floor_Temps[2],
    VI_Type := 1,
    VI_Calib_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[4],
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Start_Verification := (
        GVL_CONFIG.G_HMI_Sensor_Calibrations[4].last_calibration_timestamp <> 0 AND
        GVL_CONFIG.G_HMI_Sensor_Calibrations[4].last_calibration_timestamp <> L_FloorTemp2_Calib_TS_Prev
    )
);

GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Active := TRUE;
GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Verification_Active :=
    fbCalibVerifyFloorTemp2.VO_Verification_Active;
GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Verification_Failed :=
    fbCalibVerifyFloorTemp2.VO_Verification_Failed;
GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Deviation_Percent :=
    fbCalibVerifyFloorTemp2.VO_Deviation_Percent;

IF GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Verification_Failed THEN
    GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Summary_Text := 'FloorTemp2 verification failed';
ELSIF GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Verification_Active THEN
    GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Summary_Text := 'FloorTemp2 verification active';
ELSE
    GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Summary_Text := 'FloorTemp2 verification idle';
END_IF;

IF L_FloorTemp2_Verification_Active_Prev AND
   (NOT fbCalibVerifyFloorTemp2.VO_Verification_Active) THEN
    GVL_CONFIG.G_HMI_Sensor_Calibrations[4].verification_passed :=
        NOT fbCalibVerifyFloorTemp2.VO_Verification_Failed;
END_IF;

L_FloorTemp2_Verification_Active_Prev := fbCalibVerifyFloorTemp2.VO_Verification_Active;
L_FloorTemp2_Calib_TS_Prev := GVL_CONFIG.G_HMI_Sensor_Calibrations[4].last_calibration_timestamp;

// === OUTDOOR TEMP CALIBRATION OBSERVER ===
fbCalibOutdoorTemp(
    VI_Raw_Value := GVL_STATE.G_Outdoor_Temp,
    VI_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[5]
);
L_OutdoorTemp_Calibrated := fbCalibOutdoorTemp.VO_Calibrated_Value;

fbCalibVerifyOutdoorTemp(
    VI_Raw_Value := GVL_STATE.G_Outdoor_Temp,
    VI_Type := 1,
    VI_Calib_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[5],
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Start_Verification := (
        GVL_CONFIG.G_HMI_Sensor_Calibrations[5].last_calibration_timestamp <> 0 AND
        GVL_CONFIG.G_HMI_Sensor_Calibrations[5].last_calibration_timestamp <> L_OutdoorTemp_Calib_TS_Prev
    )
);

GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Active := TRUE;
GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Verification_Active :=
    fbCalibVerifyOutdoorTemp.VO_Verification_Active;
GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Verification_Failed :=
    fbCalibVerifyOutdoorTemp.VO_Verification_Failed;
GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Deviation_Percent :=
    fbCalibVerifyOutdoorTemp.VO_Deviation_Percent;

IF GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Verification_Failed THEN
    GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Summary_Text := 'OutdoorTemp verification failed';
ELSIF GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Verification_Active THEN
    GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Summary_Text := 'OutdoorTemp verification active';
ELSE
    GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Summary_Text := 'OutdoorTemp verification idle';
END_IF;

IF L_OutdoorTemp_Verification_Active_Prev AND
   (NOT fbCalibVerifyOutdoorTemp.VO_Verification_Active) THEN
    GVL_CONFIG.G_HMI_Sensor_Calibrations[5].verification_passed :=
        NOT fbCalibVerifyOutdoorTemp.VO_Verification_Failed;
END_IF;

L_OutdoorTemp_Verification_Active_Prev := fbCalibVerifyOutdoorTemp.VO_Verification_Active;
L_OutdoorTemp_Calib_TS_Prev := GVL_CONFIG.G_HMI_Sensor_Calibrations[5].last_calibration_timestamp;
"""

new_block = """// === TEMPERATURE FAMILY CALIBRATION GENERIC LOOP ===
// Mapping:
// 1 -> FloorTemp1, calibration record 3
// 2 -> FloorTemp2, calibration record 4
// 3 -> OutdoorTemp, calibration record 5
FOR L_i := 1 TO 3 DO
    CASE L_i OF
        1:
            L_TempFamily_Raw := GVL_STATE.G_Floor_Temps[1];
        2:
            L_TempFamily_Raw := GVL_STATE.G_Floor_Temps[2];
        3:
            L_TempFamily_Raw := GVL_STATE.G_Outdoor_Temp;
    ELSE
        L_TempFamily_Raw := 0.0;
    END_CASE;

    fbCalibTempFamily[L_i](
        VI_Raw_Value := L_TempFamily_Raw,
        VI_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[L_i + 2]
    );
    L_TempFamily_Calibrated[L_i] := fbCalibTempFamily[L_i].VO_Calibrated_Value;

    fbCalibVerifyTempFamily[L_i](
        VI_Raw_Value := L_TempFamily_Raw,
        VI_Type := 1,
        VI_Calib_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[L_i + 2],
        VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
        VI_Start_Verification := (
            GVL_CONFIG.G_HMI_Sensor_Calibrations[L_i + 2].last_calibration_timestamp <> 0 AND
            GVL_CONFIG.G_HMI_Sensor_Calibrations[L_i + 2].last_calibration_timestamp <> L_TempFamily_Calib_TS_Prev[L_i]
        )
    );

    CASE L_i OF
        1:
            GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Active := TRUE;
            GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Verification_Active :=
                fbCalibVerifyTempFamily[L_i].VO_Verification_Active;
            GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Verification_Failed :=
                fbCalibVerifyTempFamily[L_i].VO_Verification_Failed;
            GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Deviation_Percent :=
                fbCalibVerifyTempFamily[L_i].VO_Deviation_Percent;

            IF GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Verification_Failed THEN
                GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Summary_Text := 'FloorTemp1 verification failed';
            ELSIF GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Verification_Active THEN
                GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Summary_Text := 'FloorTemp1 verification active';
            ELSE
                GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Summary_Text := 'FloorTemp1 verification idle';
            END_IF;

        2:
            GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Active := TRUE;
            GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Verification_Active :=
                fbCalibVerifyTempFamily[L_i].VO_Verification_Active;
            GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Verification_Failed :=
                fbCalibVerifyTempFamily[L_i].VO_Verification_Failed;
            GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Deviation_Percent :=
                fbCalibVerifyTempFamily[L_i].VO_Deviation_Percent;

            IF GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Verification_Failed THEN
                GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Summary_Text := 'FloorTemp2 verification failed';
            ELSIF GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Verification_Active THEN
                GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Summary_Text := 'FloorTemp2 verification active';
            ELSE
                GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Summary_Text := 'FloorTemp2 verification idle';
            END_IF;

        3:
            GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Active := TRUE;
            GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Verification_Active :=
                fbCalibVerifyTempFamily[L_i].VO_Verification_Active;
            GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Verification_Failed :=
                fbCalibVerifyTempFamily[L_i].VO_Verification_Failed;
            GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Deviation_Percent :=
                fbCalibVerifyTempFamily[L_i].VO_Deviation_Percent;

            IF GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Verification_Failed THEN
                GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Summary_Text := 'OutdoorTemp verification failed';
            ELSIF GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Verification_Active THEN
                GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Summary_Text := 'OutdoorTemp verification active';
            ELSE
                GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Summary_Text := 'OutdoorTemp verification idle';
            END_IF;
    END_CASE;

    IF L_TempFamily_Verification_Active_Prev[L_i] AND
       (NOT fbCalibVerifyTempFamily[L_i].VO_Verification_Active) THEN
        GVL_CONFIG.G_HMI_Sensor_Calibrations[L_i + 2].verification_passed :=
            NOT fbCalibVerifyTempFamily[L_i].VO_Verification_Failed;
    END_IF;

    L_TempFamily_Verification_Active_Prev[L_i] := fbCalibVerifyTempFamily[L_i].VO_Verification_Active;
    L_TempFamily_Calib_TS_Prev[L_i] := GVL_CONFIG.G_HMI_Sensor_Calibrations[L_i + 2].last_calibration_timestamp;
END_FOR;
"""

if old_block not in text:
    raise SystemExit("Expected scalar temperature observer block not found exactly")

text = text.replace(old_block, new_block, 1)

prg.write_text(text, encoding="utf-8")
print("OK: temperature family generic loop integrated")
