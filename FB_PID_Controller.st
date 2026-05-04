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

(* explicit cast for safety *)
L_Cycle_Time_Safe := REAL(VI_Cycle_Time_S);

END_FUNCTION_BLOCK
