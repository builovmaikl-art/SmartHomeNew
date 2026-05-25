FUNCTION_BLOCK FB_Sensor_Calibration_Processor
VAR_INPUT
    VI_Raw_Value : REAL;
    VI_Record    : ST_Sensor_Calibration_Record;
END_VAR
VAR_OUTPUT
    VO_Calibrated_Value : REAL;
    VO_Record_Valid : BOOL;
    VO_Calibration_Applied : BOOL;
    VO_Record_Fault : BOOL;
    VO_Used_Offset : REAL;
    VO_Used_Multiplier : REAL;
    VO_Last_Calibration_Timestamp : UDINT;
END_VAR
VAR
    L_Record_Has_Correction : BOOL;
    L_Multiplier_In_Range : BOOL;
END_VAR

// Calibration records are allowed to be neutral by default:
// multiplier=1.0, offset=0.0, verification_passed=FALSE.
// Non-neutral corrections must be verified before they affect normalized IO.
L_Record_Has_Correction := (VI_Record.offset <> 0.0) OR (VI_Record.multiplier <> 1.0);
L_Multiplier_In_Range := (VI_Record.multiplier >= 0.01) AND (VI_Record.multiplier <= 100.0);

VO_Record_Valid := TRUE;
VO_Record_Fault := FALSE;
VO_Calibration_Applied := FALSE;
VO_Used_Offset := 0.0;
VO_Used_Multiplier := 1.0;
VO_Last_Calibration_Timestamp := VI_Record.last_calibration_timestamp;

IF NOT L_Multiplier_In_Range THEN
    VO_Record_Valid := FALSE;
    VO_Record_Fault := TRUE;
ELSIF L_Record_Has_Correction AND NOT VI_Record.verification_passed THEN
    VO_Record_Valid := FALSE;
    VO_Record_Fault := TRUE;
END_IF;

IF VO_Record_Valid THEN
    VO_Used_Offset := VI_Record.offset;
    VO_Used_Multiplier := VI_Record.multiplier;
    VO_Calibration_Applied := L_Record_Has_Correction OR (VI_Record.last_calibration_timestamp <> 0);
    VO_Calibrated_Value := (VI_Raw_Value * VI_Record.multiplier) + VI_Record.offset;
ELSE
    // Fail safe for invalid calibration records: publish raw normalized input
    // and let the caller raise diagnostics through VO_Record_Fault.
    VO_Calibrated_Value := VI_Raw_Value;
END_IF;
END_FUNCTION_BLOCK
