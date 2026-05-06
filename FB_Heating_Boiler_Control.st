// ==============================================================================
// Heating boiler control helper
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
    L_Transport_Degraded : BOOL;
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
    // Boiler demand is a primary-circuit heat request.
    // Consumer-side temperature limitation is handled downstream by manifolds or the DHW heat exchanger.
    // Gas safety disables DHW demand earlier in PRG_Heating, so this does not allow DHW heating during gas shutdown.
    VI_Enable := VI_IsActivePLC AND ((VO_Demand_Power > GVL_CONSTANTS.C_BOILER_CASCADE_MIN_DEMAND) OR VI_Freeze_Mode_Active OR VI_DHW_Heating_Demand),
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

// === PRIMARY CIRCUIT SETPOINT CLAMP ===
// The boiler heats the primary heat carrier to the requested temperature margin.
// It must not enforce floor or DHW consumer limits here: manifolds and the DHW heat exchanger own final consumer-side regulation.
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BOILERS DO
    IF L_Boiler_Request_Enable[L_i] THEN
        L_Boiler_Request_Setpoint[L_i] := LIMIT(
            GVL_CONSTANTS.C_BOILER_SETPOINT_MIN,
            L_Boiler_Request_Setpoint[L_i],
            80.0
        );
    END_IF;
END_FOR;

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

    L_Transport_Degraded :=
        L_Boiler_Request_Enable[L_i] AND
        (
            NOT L_Boiler_OT_Command_Valid[L_i] OR
            NOT VI_Boiler_OT_Online[L_i] OR
            VI_Boiler_Error_Status[L_i]
        );

    // ======================================================
    // TRANSPORT / ADAPTER OBSERVABILITY
    // ======================================================
    VO_Boiler_Status[L_i].OT_Online := VI_Boiler_OT_Online[L_i];
    VO_Boiler_Status[L_i].OT_Command_Valid := L_Boiler_OT_Command_Valid[L_i];
    VO_Boiler_Status[L_i].OT_Transport_Degraded := L_Transport_Degraded;
    VO_Boiler_Status[L_i].OT_Adapter_Error :=
        GVL_OPENTHERM_ADAPTER.G_Status[L_i].Adapter_Error;

    // ======================================================
    // BOILER STATE FLAGS
    // ======================================================
    VO_Boiler_Status[L_i].Active := L_Boiler_Request_Enable[L_i];
    VO_Boiler_Status[L_i].Running := VI_Boiler_Flame_Status[L_i];
    VO_Boiler_Status[L_i].Warning := L_Transport_Degraded;
    VO_Boiler_Status[L_i].Error := VI_Boiler_Error_Status[L_i];

    IF L_Transport_Degraded THEN
        VO_Any_Subsystem_Degraded := TRUE;
    END_IF;

END_FOR;

// (остальной код без изменений)

END_FUNCTION_BLOCK
