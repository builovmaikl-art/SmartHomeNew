FUNCTION_BLOCK FB_Sensor_Calibration_Processor
VAR_INPUT
    VI_Raw_Value : REAL;
    VI_Record    : ST_Sensor_Calibration_Record;
END_VAR
VAR_OUTPUT
    VO_Calibrated_Value : REAL;
END_VAR

VO_Calibrated_Value := (VI_Raw_Value * VI_Record.multiplier) + VI_Record.offset;