FUNCTION_BLOCK FB_Sensor_Calibration
VAR_INPUT
    VI_Sensor_ID : UDINT;
    VI_Reference_Value : REAL;
    VI_Current_Value : REAL;
    VI_Apply : BOOL;
END_VAR
VAR_OUTPUT
    VO_Offset : REAL;
    VO_Multiplier : REAL := 1.0;
    VO_Done : BOOL;
END_VAR
VAR
    L_Applied : BOOL;
END_VAR

IF VI_Apply AND NOT L_Applied THEN
    // Простая калибровка смещением (одноточечная)
    VO_Offset := VI_Reference_Value - VI_Current_Value;
    VO_Done := TRUE;
    L_Applied := TRUE;
ELSIF NOT VI_Apply THEN
    VO_Done := FALSE;
    L_Applied := FALSE;
END_IF;