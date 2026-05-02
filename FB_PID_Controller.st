FUNCTION_BLOCK FB_PID_Controller
VAR_INPUT
    VI_SetPoint : REAL;
    VI_ProcessValue : REAL;
    VI_Kp : REAL;
    VI_Tn : REAL;
    VI_Tv : REAL;
    VI_Y_Min : REAL := 0.0;
    VI_Y_Max : REAL := 100.0;
    VI_Manual_Mode : BOOL;
    VI_Manual_Value : REAL;
    VI_Deadband : REAL := 0.1;
    VI_Cycle_Time_S : REAL := 0.01;
    VI_Reset : BOOL;
END_VAR
VAR_OUTPUT
    VO_Output : REAL;
    VO_Error : REAL;
    VO_Limiting : BOOL;
END_VAR
VAR
    L_Integral_Sum : REAL;
    L_Prev_Error : REAL;
    L_Derivative : REAL;
    L_P_Term : REAL;
    L_I_Candidate : REAL;
    L_D_Term : REAL;
    L_Output_Predicted : REAL;
    L_Output_Raw : REAL;
    L_Cycle_Time_Safe : REAL;
END_VAR

L_Cycle_Time_Safe := VI_Cycle_Time_S;
IF L_Cycle_Time_Safe <= 0.0 THEN
    L_Cycle_Time_Safe := 0.01;
END_IF;

VO_Error := VI_SetPoint - VI_ProcessValue;
IF ABS(VO_Error) < VI_Deadband THEN
    VO_Error := 0.0;
END_IF;

IF VI_Reset THEN
    L_Integral_Sum := 0.0;
    L_Prev_Error := 0.0;
    VO_Output := LIMIT(VI_Y_Min, 0.0, VI_Y_Max);
    VO_Limiting := FALSE;
    RETURN;
END_IF;

L_P_Term := VI_Kp * VO_Error;

IF VI_Tv > 0.0 THEN
    L_Derivative := (VO_Error - L_Prev_Error) / L_Cycle_Time_Safe;
    L_D_Term := VI_Kp * VI_Tv * L_Derivative;
ELSE
    L_Derivative := 0.0;
    L_D_Term := 0.0;
END_IF;

IF VI_Manual_Mode THEN
    VO_Output := LIMIT(VI_Y_Min, VI_Manual_Value, VI_Y_Max);
    L_Integral_Sum := VO_Output - L_P_Term - L_D_Term;
    L_Prev_Error := VO_Error;
    VO_Limiting := (VO_Output <= VI_Y_Min) OR (VO_Output >= VI_Y_Max);
    RETURN;
END_IF;

IF VI_Tn > 0.0 THEN
    L_I_Candidate := L_Integral_Sum + ((VI_Kp / VI_Tn) * VO_Error * L_Cycle_Time_Safe);
ELSE
    L_I_Candidate := L_Integral_Sum;
END_IF;

L_Output_Predicted := L_P_Term + L_I_Candidate + L_D_Term;

// Anti-windup: accept the new integral only if it does not push the output farther into saturation.
IF VI_Tn > 0.0 THEN
    IF (L_Output_Predicted > VI_Y_Max) AND (VO_Error > 0.0) THEN
        // hold integral
    ELSIF (L_Output_Predicted < VI_Y_Min) AND (VO_Error < 0.0) THEN
        // hold integral
    ELSE
        L_Integral_Sum := L_I_Candidate;
    END_IF;
END_IF;

L_Output_Raw := L_P_Term + L_Integral_Sum + L_D_Term;
VO_Output := LIMIT(VI_Y_Min, L_Output_Raw, VI_Y_Max);
VO_Limiting := (L_Output_Raw > VI_Y_Max) OR (L_Output_Raw < VI_Y_Min);
L_Prev_Error := VO_Error;

// >>> BULK_SYNC_ANCHOR: FB_PID_Controller <<<
