FUNCTION_BLOCK FB_Input_Quality_Observer
VAR_INPUT
    VI_Enable : BOOL;
    VI_Value : REAL;
    VI_System_Time_MS : UDINT;
    VI_Spike_Threshold : REAL;
    VI_Stuck_Timeout_MS : UDINT;
END_VAR
VAR_OUTPUT
    VO_Quality : ST_Input_Quality_Record;
END_VAR
VAR
    L_Last_Value : REAL;
    L_Last_Change_MS : UDINT;
    L_Delta : REAL;
END_VAR

VO_Quality.Quality_Visible := VI_Enable;

IF NOT VI_Enable THEN
    RETURN;
END_IF;

VO_Quality.Value_Valid := TRUE;
VO_Quality.Value_Degraded := FALSE;
VO_Quality.Spike_Detected := FALSE;
VO_Quality.Stuck_Detected := FALSE;
VO_Quality.Confidence := REAL#1.0;
VO_Quality.Reason_Code := 0;
VO_Quality.Reason_Text := 'OK';

L_Delta := ABS(VI_Value - L_Last_Value);

IF L_Delta > VI_Spike_Threshold THEN
    VO_Quality.Spike_Detected := TRUE;
    VO_Quality.Value_Degraded := TRUE;
    VO_Quality.Confidence := REAL#0.4;
    VO_Quality.Reason_Code := 1;
    VO_Quality.Reason_Text := 'Spike detected';
END_IF;

IF L_Delta > REAL#0.05 THEN
    L_Last_Change_MS := VI_System_Time_MS;
END_IF;

IF (VI_System_Time_MS > L_Last_Change_MS) AND
   ((VI_System_Time_MS - L_Last_Change_MS) > VI_Stuck_Timeout_MS) THEN

    VO_Quality.Stuck_Detected := TRUE;
    VO_Quality.Value_Degraded := TRUE;

    IF VO_Quality.Confidence > REAL#0.6 THEN
        VO_Quality.Confidence := REAL#0.6;
    END_IF;

    IF VO_Quality.Reason_Code = 0 THEN
        VO_Quality.Reason_Code := 2;
        VO_Quality.Reason_Text := 'Sensor appears stuck';
    END_IF;
END_IF;

VO_Quality.Last_Value := VI_Value;
VO_Quality.Last_Change_MS := L_Last_Change_MS;

L_Last_Value := VI_Value;

END_FUNCTION_BLOCK
