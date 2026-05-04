// ==============================================================================
// Heating manifold control helper
// Internal refactoring helper for FB_Heating_System_Manager.
// Valve test override remains in FB_Heating_System_Manager for now.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Manifold_Control
VAR_INPUT
    VI_System_Time_MS : UDINT;
    VI_IsActivePLC : BOOL;
    VI_DHW_Heating_Demand : BOOL;
    VI_Freeze_Mode_Active : BOOL;
    VI_Target_Supply_Temp : REAL;
    VI_Any_Zone_Active : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
END_VAR

VAR_IN_OUT
    VI_Manifold_Pressures : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL;
    VI_Manifold_Currents : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL;
    VI_Manifold_Temps_Supply : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL;
    VI_Manifold_Temps_Return : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL;
END_VAR

VAR_OUTPUT
    VO_Manifold_Pumps : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    VO_Manifold_Valves : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL;
    VO_Status : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF ST_Manifold_Status;
END_VAR

VAR
    L_i : INT;
    L_Delta_T : REAL;
    L_PID_Valves : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF FB_PID_Controller;
    L_PID_Timer : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF FB_System_Timer;
    L_Pump_Run_Timer : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF FB_System_Timer;
    L_Pump_Pause_Timer : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF FB_System_Timer;
    L_Pump_In_Pause : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    L_Pump_Diag : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF FB_Device_Predictive_Diag;
END_VAR

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    L_PID_Timer[L_i](IN := TRUE, PT := T#1s, VI_System_Time_MS := VI_System_Time_MS);
    IF L_PID_Timer[L_i].Q THEN
        L_PID_Timer[L_i](IN := FALSE, PT := T#1s, VI_System_Time_MS := VI_System_Time_MS);
        L_PID_Timer[L_i](IN := TRUE, PT := T#1s, VI_System_Time_MS := VI_System_Time_MS);

        L_PID_Valves[L_i](
            VI_SetPoint := VI_Target_Supply_Temp,
            VI_ProcessValue := VI_Manifold_Temps_Supply[L_i],
            VI_Kp := 2.0,
            VI_Tn := 120.0,
            VI_Tv := 0.0,
            VI_Y_Min := 0.0,
            VI_Y_Max := 100.0,
            VI_Cycle_Time_S := 1.0,
            VO_Output => VO_Manifold_Valves[L_i]
        );
    END_IF;

    L_Pump_Run_Timer[L_i](
        IN := VO_Manifold_Pumps[L_i] AND NOT L_Pump_In_Pause[L_i],
        PT := T#72h,
        VI_System_Time_MS := VI_System_Time_MS
    );
    IF L_Pump_Run_Timer[L_i].Q THEN
        L_Pump_In_Pause[L_i] := TRUE;
    END_IF;

    L_Pump_Pause_Timer[L_i](
        IN := L_Pump_In_Pause[L_i],
        PT := T#1h,
        VI_System_Time_MS := VI_System_Time_MS
    );
    IF L_Pump_Pause_Timer[L_i].Q THEN
        L_Pump_In_Pause[L_i] := FALSE;
    END_IF;

    IF VI_DHW_Heating_Demand THEN
        VO_Manifold_Pumps[L_i] := FALSE;
        VO_Manifold_Valves[L_i] := 0.0;
    ELSE
        VO_Manifold_Pumps[L_i] := VI_IsActivePLC AND VI_Any_Zone_Active[L_i] AND NOT L_Pump_In_Pause[L_i];
    END_IF;

    IF VI_Freeze_Mode_Active THEN
        VO_Manifold_Pumps[L_i] := TRUE;
        IF VO_Manifold_Valves[L_i] < 35.0 THEN
            VO_Manifold_Valves[L_i] := 35.0;
        END_IF;
    END_IF;

    VO_Status[L_i].Pump_On := VO_Manifold_Pumps[L_i];
    VO_Status[L_i].Pump_Current := VI_Manifold_Currents[L_i];
    VO_Status[L_i].Pressure := VI_Manifold_Pressures[L_i];
    VO_Status[L_i].Temp_Supply := VI_Manifold_Temps_Supply[L_i];
    VO_Status[L_i].Temp_Return := VI_Manifold_Temps_Return[L_i];
    VO_Status[L_i].Valve_Pos := VO_Manifold_Valves[L_i];

    L_Pump_Diag[L_i](
        VI_Current_Value := VI_Manifold_Currents[L_i],
        VI_Nominal_Value := 0.55,
        VI_Is_Running := VO_Manifold_Pumps[L_i],
        VI_Reset_Stats := FALSE,
        VI_System_Time_MS := VI_System_Time_MS,
        VIO_Health_Data := VO_Status[L_i].Health
    );

    IF VO_Manifold_Pumps[L_i] THEN
        L_Delta_T := VI_Manifold_Temps_Supply[L_i] - VI_Manifold_Temps_Return[L_i];

        VO_Status[L_i].Error := FALSE;
        VO_Status[L_i].Error_ID := 0;

        IF VI_Manifold_Currents[L_i] <= 0.01 THEN
            VO_Status[L_i].Error := TRUE;
            VO_Status[L_i].Error_ID := TO_WORD(GVL_CONFIG.ERR_PUMP_NO_CURRENT);
        ELSIF VI_Manifold_Currents[L_i] < 0.3 THEN
            VO_Status[L_i].Error := TRUE;
            VO_Status[L_i].Error_ID := TO_WORD(GVL_CONFIG.ERR_PUMP_UNDERCURRENT);
        ELSIF VI_Manifold_Currents[L_i] > 1.5 THEN
            VO_Status[L_i].Error := TRUE;
            VO_Status[L_i].Error_ID := TO_WORD(GVL_CONFIG.ERR_PUMP_OVERCURRENT);
        END_IF;

        IF (NOT VO_Status[L_i].Error) AND ((VI_Manifold_Pressures[L_i] < 1.5) OR (VI_Manifold_Pressures[L_i] > 2.5)) THEN
            VO_Status[L_i].Error := TRUE;
            VO_Status[L_i].Error_ID := TO_WORD(GVL_CONFIG.ERR_PRESSURE_OUT_OF_RANGE);
        END_IF;

        IF NOT VO_Status[L_i].Error THEN
            IF L_Delta_T < 5.0 THEN
                VO_Status[L_i].Error := TRUE;
                VO_Status[L_i].Error_ID := TO_WORD(GVL_CONFIG.ERR_DELTA_T_LOW);
            ELSIF L_Delta_T > 10.0 THEN
                VO_Status[L_i].Error := TRUE;
                VO_Status[L_i].Error_ID := TO_WORD(GVL_CONFIG.ERR_DELTA_T_HIGH);
            END_IF;
        END_IF;
    END_IF;
END_FOR;

// >>> BULK_SYNC_ANCHOR: FB_Heating_Manifold_Control <<<
