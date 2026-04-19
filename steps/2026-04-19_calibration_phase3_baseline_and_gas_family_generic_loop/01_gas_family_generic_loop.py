from pathlib import Path

prg = Path("PRG_System.st")
text = prg.read_text(encoding="utf-8")

# ------------------------------------------------------------
# 1) Replace scalar gas calibration FB declarations with arrays
# ------------------------------------------------------------
old_fb = """fbCalibCO  : FB_Sensor_Calibration_Processor;
fbSensorMethane : FB_Sensor_Analog_Processing;
fbCalibMethane  : FB_Sensor_Calibration_Processor;
fbCalibVerifyCO : FB_Calibration_Manager;
fbCalibVerifyMethane : FB_Calibration_Manager;"""

new_fb = """fbCalibGasFamily : ARRAY[1..2] OF FB_Sensor_Calibration_Processor;
fbSensorMethane : FB_Sensor_Analog_Processing;
fbCalibVerifyGasFamily : ARRAY[1..2] OF FB_Calibration_Manager;"""

if old_fb not in text:
    raise SystemExit("Gas FB declaration block not found exactly")

text = text.replace(old_fb, new_fb, 1)

# ------------------------------------------------------------
# 2) Replace scalar gas state vars with generic family vars
# ------------------------------------------------------------
old_vals = """L_CO_Processed : REAL;
L_CO_Calibrated : REAL;
L_Safety_Selector_i : INT;
L_Methane_Processed : REAL;
L_Methane_Calibrated : REAL;"""

new_vals = """L_CO_Processed : REAL;
L_CO_Calibrated : REAL;
L_Safety_Selector_i : INT;
L_Methane_Processed : REAL;
L_Methane_Calibrated : REAL;
L_GasFamily_Processed : REAL;
L_GasFamily_Calibrated : ARRAY[1..2] OF REAL;"""

if old_vals not in text:
    raise SystemExit("Gas value declaration block not found exactly")

text = text.replace(old_vals, new_vals, 1)

old_prev = """L_CO_Calib_TS_Prev : UDINT;
L_Methane_Calib_TS_Prev : UDINT;
L_CO_Verification_Active_Prev : BOOL;
L_Methane_Verification_Active_Prev : BOOL;"""

new_prev = """L_GasFamily_Calib_TS_Prev : ARRAY[1..2] OF UDINT;
L_GasFamily_Verification_Active_Prev : ARRAY[1..2] OF BOOL;"""

if old_prev not in text:
    raise SystemExit("Gas prev-state declaration block not found exactly")

text = text.replace(old_prev, new_prev, 1)

if "L_GasFamily_i : INT;" not in text:
    anchor = "    L_TempFamily_i : INT;"
    if anchor not in text:
        raise SystemExit("Anchor for L_GasFamily_i not found")
    text = text.replace(anchor, anchor + "\n    L_GasFamily_i : INT;", 1)

# ------------------------------------------------------------
# 3) Replace scalar gas calibration/verification/writeback/telemetry block
# ------------------------------------------------------------
old_block = """fbCalibCO(
    VI_Raw_Value := L_CO_Processed,
    VI_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[1]
);
L_CO_Calibrated := fbCalibCO.VO_Calibrated_Value;

// === SHADOW EXPORT ===
GVL_Sensor_Shadow.G_CO_Raw := GVL_STATE.G_CO_Sensors[1];
GVL_Sensor_Shadow.G_CO_Processed := L_CO_Processed;
GVL_Sensor_Shadow.G_CO_Calibrated := L_CO_Calibrated;
GVL_Sensor_Shadow.G_CO_Error := fbSensorCO.VO_Error;
GVL_Sensor_Shadow.G_CO_Diag_Code := fbSensorCO.VO_Diag_Code;


// === METHANE SHADOW EXEC ===
fbSensorMethane(
    VI_Raw_Value := REAL_TO_WORD(GVL_STATE.G_Methane_Sensors[1]),
    VI_Sensor_Type := 0,
    VI_Min_Scale := 0.0,
    VI_Max_Scale := 100.0,
    VI_Offset := 0.0,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);
L_Methane_Processed := fbSensorMethane.VO_Value;

fbCalibMethane(
    VI_Raw_Value := L_Methane_Processed,
    VI_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[2]
);
L_Methane_Calibrated := fbCalibMethane.VO_Calibrated_Value;

// === CALIBRATION VERIFICATION OBSERVER ===
fbCalibVerifyCO(
    VI_Raw_Value := L_CO_Processed,
    VI_Type := 3,
    VI_Calib_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[1],
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Start_Verification := (
        GVL_CONFIG.G_HMI_Sensor_Calibrations[1].last_calibration_timestamp <> 0 AND
        GVL_CONFIG.G_HMI_Sensor_Calibrations[1].last_calibration_timestamp <> L_CO_Calib_TS_Prev
    )
);

fbCalibVerifyMethane(
    VI_Raw_Value := L_Methane_Processed,
    VI_Type := 3,
    VI_Calib_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[2],
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Start_Verification := (
        GVL_CONFIG.G_HMI_Sensor_Calibrations[2].last_calibration_timestamp <> 0 AND
        GVL_CONFIG.G_HMI_Sensor_Calibrations[2].last_calibration_timestamp <> L_Methane_Calib_TS_Prev
    )
);

GVL_STATUS.G_Diagnostics.Calibration_CO_Verification_Active :=
    fbCalibVerifyCO.VO_Verification_Active;
GVL_STATUS.G_Diagnostics.Calibration_CO_Verification_Failed :=
    fbCalibVerifyCO.VO_Verification_Failed;
GVL_STATUS.G_Diagnostics.Calibration_CO_Deviation_Percent :=
    fbCalibVerifyCO.VO_Deviation_Percent;

GVL_STATUS.G_Diagnostics.Calibration_Methane_Verification_Active :=
    fbCalibVerifyMethane.VO_Verification_Active;
GVL_STATUS.G_Diagnostics.Calibration_Methane_Verification_Failed :=
    fbCalibVerifyMethane.VO_Verification_Failed;
GVL_STATUS.G_Diagnostics.Calibration_Methane_Deviation_Percent :=
    fbCalibVerifyMethane.VO_Deviation_Percent;

IF GVL_STATUS.G_Diagnostics.Calibration_CO_Verification_Failed THEN
    GVL_STATUS.G_Diagnostics.Calibration_Verification_Summary_Text := 'CO calibration verification failed';
ELSIF GVL_STATUS.G_Diagnostics.Calibration_Methane_Verification_Failed THEN
    GVL_STATUS.G_Diagnostics.Calibration_Verification_Summary_Text := 'Methane calibration verification failed';
ELSIF GVL_STATUS.G_Diagnostics.Calibration_CO_Verification_Active OR
      GVL_STATUS.G_Diagnostics.Calibration_Methane_Verification_Active THEN
    GVL_STATUS.G_Diagnostics.Calibration_Verification_Summary_Text := 'Calibration verification active';
ELSE
    GVL_STATUS.G_Diagnostics.Calibration_Verification_Summary_Text := 'Calibration verification idle';
END_IF;

// === CALIBRATION VERIFICATION WRITE-BACK ===
// write result once on verification completion edge
IF L_CO_Verification_Active_Prev AND
   (NOT fbCalibVerifyCO.VO_Verification_Active) THEN
    GVL_CONFIG.G_HMI_Sensor_Calibrations[1].verification_passed :=
        NOT fbCalibVerifyCO.VO_Verification_Failed;
END_IF;

IF L_Methane_Verification_Active_Prev AND
   (NOT fbCalibVerifyMethane.VO_Verification_Active) THEN
    GVL_CONFIG.G_HMI_Sensor_Calibrations[2].verification_passed :=
        NOT fbCalibVerifyMethane.VO_Verification_Failed;
END_IF;

// === CALIBRATION VERIFICATION TELEMETRY ===
IF L_CO_Verification_Active_Prev AND
   (NOT fbCalibVerifyCO.VO_Verification_Active) THEN
    GVL_STATUS.G_Diagnostics.Calibration_CO_Verification_Event_Count :=
        GVL_STATUS.G_Diagnostics.Calibration_CO_Verification_Event_Count + 1;
    GVL_STATUS.G_Diagnostics.Calibration_Last_Event_Time_MS := GVL_STATUS.G_System_Time_MS;

    IF fbCalibVerifyCO.VO_Verification_Failed THEN
        GVL_STATUS.G_Diagnostics.Calibration_Last_Event_Text := 'CO verification failed';
    ELSE
        GVL_STATUS.G_Diagnostics.Calibration_Last_Event_Text := 'CO verification passed';
    END_IF;
END_IF;

IF L_Methane_Verification_Active_Prev AND
   (NOT fbCalibVerifyMethane.VO_Verification_Active) THEN
    GVL_STATUS.G_Diagnostics.Calibration_Methane_Verification_Event_Count :=
        GVL_STATUS.G_Diagnostics.Calibration_Methane_Verification_Event_Count + 1;
    GVL_STATUS.G_Diagnostics.Calibration_Last_Event_Time_MS := GVL_STATUS.G_System_Time_MS;

    IF fbCalibVerifyMethane.VO_Verification_Failed THEN
        GVL_STATUS.G_Diagnostics.Calibration_Last_Event_Text := 'Methane verification failed';
    ELSE
        GVL_STATUS.G_Diagnostics.Calibration_Last_Event_Text := 'Methane verification passed';
    END_IF;
END_IF;

L_CO_Verification_Active_Prev := fbCalibVerifyCO.VO_Verification_Active;
L_Methane_Verification_Active_Prev := fbCalibVerifyMethane.VO_Verification_Active;

L_CO_Calib_TS_Prev := GVL_CONFIG.G_HMI_Sensor_Calibrations[1].last_calibration_timestamp;
L_Methane_Calib_TS_Prev := GVL_CONFIG.G_HMI_Sensor_Calibrations[2].last_calibration_timestamp;

// === METHANE SHADOW EXPORT ===
GVL_Sensor_Shadow.G_Methane_Raw := GVL_STATE.G_Methane_Sensors[1];
GVL_Sensor_Shadow.G_Methane_Processed := L_Methane_Processed;
GVL_Sensor_Shadow.G_Methane_Calibrated := L_Methane_Calibrated;
GVL_Sensor_Shadow.G_Methane_Error := fbSensorMethane.VO_Error;
GVL_Sensor_Shadow.G_Methane_Diag_Code := fbSensorMethane.VO_Diag_Code;
"""

new_block = """// === SHADOW EXPORT ===
GVL_Sensor_Shadow.G_CO_Raw := GVL_STATE.G_CO_Sensors[1];
GVL_Sensor_Shadow.G_CO_Processed := L_CO_Processed;
GVL_Sensor_Shadow.G_CO_Error := fbSensorCO.VO_Error;
GVL_Sensor_Shadow.G_CO_Diag_Code := fbSensorCO.VO_Diag_Code;


// === METHANE SHADOW EXEC ===
fbSensorMethane(
    VI_Raw_Value := REAL_TO_WORD(GVL_STATE.G_Methane_Sensors[1]),
    VI_Sensor_Type := 0,
    VI_Min_Scale := 0.0,
    VI_Max_Scale := 100.0,
    VI_Offset := 0.0,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);
L_Methane_Processed := fbSensorMethane.VO_Value;

// === GAS FAMILY CALIBRATION GENERIC LOOP ===
// Mapping:
// 1 -> CO, calibration record 1
// 2 -> Methane, calibration record 2
FOR L_GasFamily_i := 1 TO 2 DO
    CASE L_GasFamily_i OF
        1:
            L_GasFamily_Processed := L_CO_Processed;
        2:
            L_GasFamily_Processed := L_Methane_Processed;
    ELSE
        L_GasFamily_Processed := 0.0;
    END_CASE;

    fbCalibGasFamily[L_GasFamily_i](
        VI_Raw_Value := L_GasFamily_Processed,
        VI_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[L_GasFamily_i]
    );
    L_GasFamily_Calibrated[L_GasFamily_i] := fbCalibGasFamily[L_GasFamily_i].VO_Calibrated_Value;

    fbCalibVerifyGasFamily[L_GasFamily_i](
        VI_Raw_Value := L_GasFamily_Processed,
        VI_Type := 3,
        VI_Calib_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[L_GasFamily_i],
        VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
        VI_Start_Verification := (
            GVL_CONFIG.G_HMI_Sensor_Calibrations[L_GasFamily_i].last_calibration_timestamp <> 0 AND
            GVL_CONFIG.G_HMI_Sensor_Calibrations[L_GasFamily_i].last_calibration_timestamp <> L_GasFamily_Calib_TS_Prev[L_GasFamily_i]
        )
    );

    CASE L_GasFamily_i OF
        1:
            L_CO_Calibrated := L_GasFamily_Calibrated[1];
            GVL_STATUS.G_Diagnostics.Calibration_CO_Verification_Active :=
                fbCalibVerifyGasFamily[L_GasFamily_i].VO_Verification_Active;
            GVL_STATUS.G_Diagnostics.Calibration_CO_Verification_Failed :=
                fbCalibVerifyGasFamily[L_GasFamily_i].VO_Verification_Failed;
            GVL_STATUS.G_Diagnostics.Calibration_CO_Deviation_Percent :=
                fbCalibVerifyGasFamily[L_GasFamily_i].VO_Deviation_Percent;

        2:
            L_Methane_Calibrated := L_GasFamily_Calibrated[2];
            GVL_STATUS.G_Diagnostics.Calibration_Methane_Verification_Active :=
                fbCalibVerifyGasFamily[L_GasFamily_i].VO_Verification_Active;
            GVL_STATUS.G_Diagnostics.Calibration_Methane_Verification_Failed :=
                fbCalibVerifyGasFamily[L_GasFamily_i].VO_Verification_Failed;
            GVL_STATUS.G_Diagnostics.Calibration_Methane_Deviation_Percent :=
                fbCalibVerifyGasFamily[L_GasFamily_i].VO_Deviation_Percent;
    END_CASE;

    IF L_GasFamily_Verification_Active_Prev[L_GasFamily_i] AND
       (NOT fbCalibVerifyGasFamily[L_GasFamily_i].VO_Verification_Active) THEN
        GVL_CONFIG.G_HMI_Sensor_Calibrations[L_GasFamily_i].verification_passed :=
            NOT fbCalibVerifyGasFamily[L_GasFamily_i].VO_Verification_Failed;

        CASE L_GasFamily_i OF
            1:
                GVL_STATUS.G_Diagnostics.Calibration_CO_Verification_Event_Count :=
                    GVL_STATUS.G_Diagnostics.Calibration_CO_Verification_Event_Count + 1;
                GVL_STATUS.G_Diagnostics.Calibration_Last_Event_Time_MS := GVL_STATUS.G_System_Time_MS;
                IF fbCalibVerifyGasFamily[L_GasFamily_i].VO_Verification_Failed THEN
                    GVL_STATUS.G_Diagnostics.Calibration_Last_Event_Text := 'CO verification failed';
                ELSE
                    GVL_STATUS.G_Diagnostics.Calibration_Last_Event_Text := 'CO verification passed';
                END_IF;

            2:
                GVL_STATUS.G_Diagnostics.Calibration_Methane_Verification_Event_Count :=
                    GVL_STATUS.G_Diagnostics.Calibration_Methane_Verification_Event_Count + 1;
                GVL_STATUS.G_Diagnostics.Calibration_Last_Event_Time_MS := GVL_STATUS.G_System_Time_MS;
                IF fbCalibVerifyGasFamily[L_GasFamily_i].VO_Verification_Failed THEN
                    GVL_STATUS.G_Diagnostics.Calibration_Last_Event_Text := 'Methane verification failed';
                ELSE
                    GVL_STATUS.G_Diagnostics.Calibration_Last_Event_Text := 'Methane verification passed';
                END_IF;
        END_CASE;
    END_IF;

    L_GasFamily_Verification_Active_Prev[L_GasFamily_i] := fbCalibVerifyGasFamily[L_GasFamily_i].VO_Verification_Active;
    L_GasFamily_Calib_TS_Prev[L_GasFamily_i] := GVL_CONFIG.G_HMI_Sensor_Calibrations[L_GasFamily_i].last_calibration_timestamp;
END_FOR;

IF GVL_STATUS.G_Diagnostics.Calibration_CO_Verification_Failed THEN
    GVL_STATUS.G_Diagnostics.Calibration_Verification_Summary_Text := 'CO calibration verification failed';
ELSIF GVL_STATUS.G_Diagnostics.Calibration_Methane_Verification_Failed THEN
    GVL_STATUS.G_Diagnostics.Calibration_Verification_Summary_Text := 'Methane calibration verification failed';
ELSIF GVL_STATUS.G_Diagnostics.Calibration_CO_Verification_Active OR
      GVL_STATUS.G_Diagnostics.Calibration_Methane_Verification_Active THEN
    GVL_STATUS.G_Diagnostics.Calibration_Verification_Summary_Text := 'Calibration verification active';
ELSE
    GVL_STATUS.G_Diagnostics.Calibration_Verification_Summary_Text := 'Calibration verification idle';
END_IF;

// === METHANE/CO SHADOW EXPORT ===
GVL_Sensor_Shadow.G_CO_Calibrated := L_CO_Calibrated;
GVL_Sensor_Shadow.G_Methane_Raw := GVL_STATE.G_Methane_Sensors[1];
GVL_Sensor_Shadow.G_Methane_Processed := L_Methane_Processed;
GVL_Sensor_Shadow.G_Methane_Calibrated := L_Methane_Calibrated;
GVL_Sensor_Shadow.G_Methane_Error := fbSensorMethane.VO_Error;
GVL_Sensor_Shadow.G_Methane_Diag_Code := fbSensorMethane.VO_Diag_Code;
"""

if old_block not in text:
    raise SystemExit("Scalar gas calibration block not found exactly")

text = text.replace(old_block, new_block, 1)

prg.write_text(text, encoding="utf-8")
print("OK: gas family generic loop integrated")
