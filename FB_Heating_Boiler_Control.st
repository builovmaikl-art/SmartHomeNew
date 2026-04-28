// ==============================================================================
// Heating boiler control helper
//
// Internal refactoring helper for FB_Heating_System_Manager.
// Owns demand aggregation, boiler cascade request, OpenTherm transport,
// status normalization, degradation projection, and boiler resource accounting.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Boiler_Control
VAR_INPUT
    VI_System_Time_MS : UDINT;
    VI_IsActivePLC : BOOL;
    VI_DHW_Heating_Demand : BOOL;
    VI_DHW_Target_Temp : REAL;
    VI_Target_Supply_Temp : REAL;
    VI_Freeze_Mode_Active : BOOL;
    VI_Policy_Degraded : BOOL;
    VI_Manifold_Pumps : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    VI_Manifold_Valves : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL;
    VI_Boiler_Flame_Status : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF BOOL;
    VI_Boiler_Error_Status : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF BOOL;
    VI_Boiler_OT_Online : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF BOOL;
END_VAR

VAR_IN_OUT
    VI_Boiler_Modulation : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF REAL;
END_VAR

VAR_OUTPUT
    VO_Boiler_OT_Enable : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF BOOL;
    VO_Boiler_OT_Setpoint : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF REAL;
    VO_Boiler_Status : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF ST_Boiler_Status;
    VO_Any_Subsystem_Degraded : BOOL;
    VO_Lead_Boiler : BYTE;
    VO_Demand_Power : REAL;
END_VAR

VAR
    L_i : INT;
    L_Delta_MS : UDINT;
    L_Last_Scan_Time : UDINT;
    L_Scan_Time_Init : BOOL := FALSE;
    L_Boiler_Request_Enable : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF BOOL;
    L_Boiler_Request_Setpoint : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF REAL;
    L_Boiler_OT_Command_Valid : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF BOOL;
    L_Boiler_Life : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF FB_Lifetime_Predictor;
    fbBoilerCascade : FB_Boiler_Cascade_Manager;
    fbBoilerOpenTherm : FB_Boiler_OpenTherm_Interface;
END_VAR

VO_Any_Subsystem_Degraded := FALSE;
VO_Demand_Power := 0.0;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    IF VI_Manifold_Pumps[L_i] THEN
        VO_Demand_Power := VO_Demand_Power + VI_Manifold_Valves[L_i];
    END_IF;
END_FOR;

IF VI_Freeze_Mode_Active AND VO_Demand_Power < 20.0 THEN
    VO_Demand_Power := 20.0;
END_IF;

IF VI_Policy_Degraded THEN
    IF VO_Demand_Power > 60.0 THEN
        VO_Demand_Power := 60.0;
    END_IF;
END_IF;

fbBoilerCascade(
    VI_Enable := VI_IsActivePLC AND ((VO_Demand_Power > GVL_CONSTANTS.C_BOILER_CASCADE_MIN_DEMAND) OR VI_Freeze_Mode_Active),
    VI_System_Time_MS := VI_System_Time_MS,
    VI_Boiler_Stop := FALSE,
    VI_DHW_Heating_Demand := VI_DHW_Heating_Demand,
    VI_DHW_Target_Temp := VI_DHW_Target_Temp,
    VI_Target_Supply_Temp := VI_Target_Supply_Temp,
    VI_Demand_Power := VO_Demand_Power,
    VI_Boiler_Flame_Status := VI_Boiler_Flame_Status,
    VI_Boiler_Error_Status := VI_Boiler_Error_Status,
    VI_Boiler_OT_Online := VI_Boiler_OT_Online,
    VI_Boiler_Modulation := VI_Boiler_Modulation,
    VO_Boiler_Enable => L_Boiler_Request_Enable,
    VO_Boiler_Setpoint => L_Boiler_Request_Setpoint,
    VO_Lead_Boiler => VO_Lead_Boiler
);

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BOILERS DO
    IF NOT VI_Boiler_OT_Online[L_i] OR VI_Boiler_Error_Status[L_i] THEN
        L_Boiler_Request_Enable[L_i] := FALSE;
        L_Boiler_Request_Setpoint[L_i] := 0.0;
    END_IF;
END_FOR;

fbBoilerOpenTherm(
    VI_Enable := L_Boiler_Request_Enable,
    VI_Setpoint := L_Boiler_Request_Setpoint,
    VI_OT_Online := VI_Boiler_OT_Online,
    VI_OT_Error := VI_Boiler_Error_Status,
    VO_OT_Enable => VO_Boiler_OT_Enable,
    VO_OT_Setpoint => VO_Boiler_OT_Setpoint,
    VO_OT_Command_Valid => L_Boiler_OT_Command_Valid
);

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BOILERS DO
    VO_Boiler_Status[L_i].Active := L_Boiler_Request_Enable[L_i];
    VO_Boiler_Status[L_i].Warning := FALSE;
    VO_Boiler_Status[L_i].Error := FALSE;

    IF NOT VI_Boiler_OT_Online[L_i] THEN
        VO_Boiler_Status[L_i].Error := TRUE;
        VO_Boiler_Status[L_i].Error_ID := TO_WORD(GVL_CONFIG.ERR_BOILER_OFFLINE);
        VO_Any_Subsystem_Degraded := TRUE;
    ELSIF VI_Boiler_Error_Status[L_i] THEN
        VO_Boiler_Status[L_i].Error := TRUE;
        VO_Boiler_Status[L_i].Error_ID := TO_WORD(GVL_CONFIG.ERR_BOILER_GENERAL_FAULT);
        VO_Any_Subsystem_Degraded := TRUE;
    ELSIF L_Boiler_Request_Enable[L_i] AND NOT VI_Boiler_Flame_Status[L_i] THEN
        VO_Boiler_Status[L_i].Warning := TRUE;
        VO_Boiler_Status[L_i].Error_ID := TO_WORD(GVL_CONFIG.ERR_BOILER_NO_FLAME);
        VO_Any_Subsystem_Degraded := TRUE;
    ELSE
        VO_Boiler_Status[L_i].Error_ID := 0;
    END_IF;
END_FOR;

IF NOT L_Scan_Time_Init THEN
    L_Last_Scan_Time := VI_System_Time_MS;
    L_Scan_Time_Init := TRUE;
END_IF;

L_Delta_MS := (SEL(VI_System_Time_MS >= L_Last_Scan_Time, VI_System_Time_MS - L_Last_Scan_Time, (4294967295 - L_Last_Scan_Time) + VI_System_Time_MS + 1));
IF L_Delta_MS > 1000 THEN
    L_Delta_MS := 1000;
END_IF;

L_Last_Scan_Time := VI_System_Time_MS;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BOILERS DO
    VO_Boiler_Status[L_i].Work_Seconds := GVL_Retain.G_Boiler_Work_Seconds[L_i];

    IF VI_Boiler_Flame_Status[L_i] THEN
        GVL_Retain.G_Boiler_Accumulated_MS[L_i] := GVL_Retain.G_Boiler_Accumulated_MS[L_i] + L_Delta_MS;
        IF GVL_Retain.G_Boiler_Accumulated_MS[L_i] >= GVL_CONSTANTS.C_MS_IN_SECOND THEN
            GVL_Retain.G_Boiler_Work_Seconds[L_i] := GVL_Retain.G_Boiler_Work_Seconds[L_i] + (GVL_Retain.G_Boiler_Accumulated_MS[L_i] / 1000);
            GVL_Retain.G_Boiler_Accumulated_MS[L_i] := GVL_Retain.G_Boiler_Accumulated_MS[L_i] MOD 1000;

            IF GVL_Retain.G_Boiler_Work_Seconds[L_i] > 4000000000 THEN
                GVL_Retain.G_Boiler_Work_Seconds[L_i] := 0;
            END_IF;

            VO_Boiler_Status[L_i].Work_Seconds := GVL_Retain.G_Boiler_Work_Seconds[L_i];
        END_IF;
    END_IF;

    VO_Boiler_Status[L_i].Work_Hours := TO_REAL(VO_Boiler_Status[L_i].Work_Seconds) / 3600.0;

    L_Boiler_Life[L_i](
        VI_Runtime_Hours := TO_UDINT(VO_Boiler_Status[L_i].Work_Hours),
        VI_Start_Count := 0,
        VI_Nominal_Life := 50000
    );
    VO_Boiler_Status[L_i].Resource_Percent := TO_REAL(L_Boiler_Life[L_i].VO_Remaining_Percent);
    VO_Boiler_Status[L_i].Running := VI_Boiler_Flame_Status[L_i];
END_FOR;

// >>> BULK_SYNC_ANCHOR: FB_Heating_Boiler_Control <<<
