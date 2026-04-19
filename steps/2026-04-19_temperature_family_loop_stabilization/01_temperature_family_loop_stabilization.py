from pathlib import Path

prg = Path("PRG_System.st")
text = prg.read_text(encoding="utf-8")

# ------------------------------------------------------------
# 1) Add dedicated loop index + restore alias calibrated vars
# ------------------------------------------------------------
old_vars = """L_Methane_Calibrated : REAL;
L_TempFamily_Raw : REAL;
L_TempFamily_Calibrated : ARRAY[1..3] OF REAL;"""

new_vars = """L_Methane_Calibrated : REAL;
L_FloorTemp1_Calibrated : REAL;
L_FloorTemp2_Calibrated : REAL;
L_OutdoorTemp_Calibrated : REAL;
L_TempFamily_Raw : REAL;
L_TempFamily_Calibrated : ARRAY[1..3] OF REAL;"""

if "L_FloorTemp1_Calibrated : REAL;" not in text:
    if old_vars not in text:
        raise SystemExit("Calibrated value var block not found")
    text = text.replace(old_vars, new_vars, 1)

anchor = "L_i : INT;"
if "L_TempFamily_i : INT;" not in text:
    if anchor not in text:
        raise SystemExit("Anchor L_i : INT; not found")
    text = text.replace(anchor, anchor + "\n    L_TempFamily_i : INT;", 1)

# ------------------------------------------------------------
# 2) Replace generic loop to use dedicated index and alias writeback
# ------------------------------------------------------------
old_loop = """// === TEMPERATURE FAMILY CALIBRATION GENERIC LOOP ===
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

new_loop = """// === TEMPERATURE FAMILY CALIBRATION GENERIC LOOP ===
// Mapping:
// 1 -> FloorTemp1, calibration record 3
// 2 -> FloorTemp2, calibration record 4
// 3 -> OutdoorTemp, calibration record 5
FOR L_TempFamily_i := 1 TO 3 DO
    CASE L_TempFamily_i OF
        1:
            L_TempFamily_Raw := GVL_STATE.G_Floor_Temps[1];
        2:
            L_TempFamily_Raw := GVL_STATE.G_Floor_Temps[2];
        3:
            L_TempFamily_Raw := GVL_STATE.G_Outdoor_Temp;
    ELSE
        L_TempFamily_Raw := 0.0;
    END_CASE;

    fbCalibTempFamily[L_TempFamily_i](
        VI_Raw_Value := L_TempFamily_Raw,
        VI_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[L_TempFamily_i + 2]
    );
    L_TempFamily_Calibrated[L_TempFamily_i] := fbCalibTempFamily[L_TempFamily_i].VO_Calibrated_Value;

    fbCalibVerifyTempFamily[L_TempFamily_i](
        VI_Raw_Value := L_TempFamily_Raw,
        VI_Type := 1,
        VI_Calib_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[L_TempFamily_i + 2],
        VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
        VI_Start_Verification := (
            GVL_CONFIG.G_HMI_Sensor_Calibrations[L_TempFamily_i + 2].last_calibration_timestamp <> 0 AND
            GVL_CONFIG.G_HMI_Sensor_Calibrations[L_TempFamily_i + 2].last_calibration_timestamp <> L_TempFamily_Calib_TS_Prev[L_TempFamily_i]
        )
    );

    CASE L_TempFamily_i OF
        1:
            L_FloorTemp1_Calibrated := L_TempFamily_Calibrated[1];

            GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Active := TRUE;
            GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Verification_Active :=
                fbCalibVerifyTempFamily[L_TempFamily_i].VO_Verification_Active;
            GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Verification_Failed :=
                fbCalibVerifyTempFamily[L_TempFamily_i].VO_Verification_Failed;
            GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Deviation_Percent :=
                fbCalibVerifyTempFamily[L_TempFamily_i].VO_Deviation_Percent;

            IF GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Verification_Failed THEN
                GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Summary_Text := 'FloorTemp1 verification failed';
            ELSIF GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Verification_Active THEN
                GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Summary_Text := 'FloorTemp1 verification active';
            ELSE
                GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Summary_Text := 'FloorTemp1 verification idle';
            END_IF;

        2:
            L_FloorTemp2_Calibrated := L_TempFamily_Calibrated[2];

            GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Active := TRUE;
            GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Verification_Active :=
                fbCalibVerifyTempFamily[L_TempFamily_i].VO_Verification_Active;
            GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Verification_Failed :=
                fbCalibVerifyTempFamily[L_TempFamily_i].VO_Verification_Failed;
            GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Deviation_Percent :=
                fbCalibVerifyTempFamily[L_TempFamily_i].VO_Deviation_Percent;

            IF GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Verification_Failed THEN
                GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Summary_Text := 'FloorTemp2 verification failed';
            ELSIF GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Verification_Active THEN
                GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Summary_Text := 'FloorTemp2 verification active';
            ELSE
                GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Summary_Text := 'FloorTemp2 verification idle';
            END_IF;

        3:
            L_OutdoorTemp_Calibrated := L_TempFamily_Calibrated[3];

            GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Active := TRUE;
            GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Verification_Active :=
                fbCalibVerifyTempFamily[L_TempFamily_i].VO_Verification_Active;
            GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Verification_Failed :=
                fbCalibVerifyTempFamily[L_TempFamily_i].VO_Verification_Failed;
            GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Deviation_Percent :=
                fbCalibVerifyTempFamily[L_TempFamily_i].VO_Deviation_Percent;

            IF GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Verification_Failed THEN
                GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Summary_Text := 'OutdoorTemp verification failed';
            ELSIF GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Verification_Active THEN
                GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Summary_Text := 'OutdoorTemp verification active';
            ELSE
                GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Summary_Text := 'OutdoorTemp verification idle';
            END_IF;
    END_CASE;

    IF L_TempFamily_Verification_Active_Prev[L_TempFamily_i] AND
       (NOT fbCalibVerifyTempFamily[L_TempFamily_i].VO_Verification_Active) THEN
        GVL_CONFIG.G_HMI_Sensor_Calibrations[L_TempFamily_i + 2].verification_passed :=
            NOT fbCalibVerifyTempFamily[L_TempFamily_i].VO_Verification_Failed;
    END_IF;

    L_TempFamily_Verification_Active_Prev[L_TempFamily_i] := fbCalibVerifyTempFamily[L_TempFamily_i].VO_Verification_Active;
    L_TempFamily_Calib_TS_Prev[L_TempFamily_i] := GVL_CONFIG.G_HMI_Sensor_Calibrations[L_TempFamily_i + 2].last_calibration_timestamp;
END_FOR;
"""

if old_loop not in text:
    raise SystemExit("Generic loop block not found exactly")

text = text.replace(old_loop, new_loop, 1)

prg.write_text(text, encoding="utf-8")
print("OK: stabilized temperature family generic loop")
