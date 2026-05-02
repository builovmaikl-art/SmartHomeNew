FUNCTION_BLOCK FB_Heating_System_Manager
VAR_INPUT
    VI_System_Mode : E_System_Operating_Mode;
    VI_System_Time_MS : UDINT;
    VI_IsActivePLC : BOOL;
    VI_Outdoor_Temp : REAL;
    VI_Config : ST_Heating_Config;
    VI_Tariff : ST_Tariff_Config;
    VI_Current_Hour : UINT;
    VI_DHW_Heating_Demand : BOOL;
    VI_DHW_Target_Temp : REAL;
    VI_Emergency_Stop : BOOL;
    VI_Gas_Safety_Stop : BOOL;
    VI_Boiler_Error_Status : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF BOOL;
    VI_Boiler_OT_Online : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF BOOL;
    VI_Boiler_Modulation : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF REAL;
END_VAR
VAR_IN_OUT
    VI_Floor_Temps : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF REAL;
    VI_Room_Temps : ARRAY[1..16] OF REAL;
    VI_Manifold_Pressures : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL;
    VI_Manifold_Currents : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL;
    VI_Manifold_Temps_Supply : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL;
    VI_Manifold_Temps_Return : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL;
    VI_Boiler_Flame_Status : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF BOOL;
    VI_Zone_Configs : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF ST_FloorHeating_Circuit_Config;
    VI_Rule_Actions : ARRAY[1..GVL_CONSTANTS.C_MAX_RULES] OF ST_Rule_Action;
    VI_IO_Modules_Online : ARRAY[1..GVL_CONSTANTS.C_MAX_MODULES] OF BOOL;
    VI_Manifold_End_Switches : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    VI_Valve_Test_Config : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF ST_Valve_Test_Config;
END_VAR
VAR_OUTPUT
    VO_Manifold_Valves : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL;
    VO_Manifold_Pumps : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    VO_Zone_Valves : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF BOOL;
    VO_Boiler_OT_Enable : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF BOOL;
    VO_Boiler_OT_Setpoint : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF REAL;
    VO_Backup_Circulation_Pump : BOOL;
    VO_Electric_Heater_Enable : BOOL;
    VO_Freeze_Risk_Status : BOOL;
    VO_Status : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF ST_Manifold_Status;
    VO_Boiler_Status : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF ST_Boiler_Status;
END_VAR
VAR
    L_i : INT;
    L_Target_Supply_Temp : REAL;
    L_Manifold_Demand_Map : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    fbValveTestManager : FB_Valve_Test_Manager;
    L_IO_Failsafe_Active : BOOL;
    L_Freeze_Active : BOOL;
    L_Freeze_Target_Supply : REAL;
    L_Policy_Degraded : BOOL;
    L_Sensor_Error : BOOL;
    L_Subsys_Degraded : BOOL;
    L_Pressure_OK : BOOL;

    // Predictive memory
    L_Prev_Pressure : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL;
    L_Prev_Current  : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL;

    fbAdaptiveTarget : FB_Heating_Adaptive_Target;
    fbSafetyGate : FB_Heating_Safety_Gate;
    fbSafeState : FB_Heating_Safe_State;
    fbDemandMap : FB_Heating_Demand_Map;
    fbCircuitControl : FB_Heating_Circuit_Control;
    fbManifoldControl : FB_Heating_Manifold_Control;
    fbBoilerControl : FB_Heating_Boiler_Control;
END_VAR

// --- (SAFE STATE + CONTROL unchanged, shortened for clarity) ---

fbManifoldControl(
    VI_System_Time_MS := VI_System_Time_MS,
    VI_IsActivePLC := VI_IsActivePLC,
    VI_DHW_Heating_Demand := VI_DHW_Heating_Demand,
    VI_Freeze_Mode_Active := L_Freeze_Active,
    VI_Target_Supply_Temp := L_Target_Supply_Temp,
    VI_Any_Zone_Active := L_Manifold_Demand_Map,
    VI_Manifold_Pressures := VI_Manifold_Pressures,
    VI_Manifold_Currents := VI_Manifold_Currents,
    VI_Manifold_Temps_Supply := VI_Manifold_Temps_Supply,
    VI_Manifold_Temps_Return := VI_Manifold_Temps_Return,
    VO_Manifold_Pumps => VO_Manifold_Pumps,
    VO_Manifold_Valves => VO_Manifold_Valves,
    VO_Status => VO_Status
);

// --- SAFETY CLAMP ---
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    L_Pressure_OK := VI_Manifold_Pressures[L_i] >= GVL_CONSTANTS.C_MIN_HEATING_MANIFOLD_PRESSURE;

    IF VO_Manifold_Pumps[L_i] AND NOT L_Pressure_OK THEN
        VO_Manifold_Pumps[L_i] := FALSE;
        GVL_STATE.G_Heating_Subsystem_Degraded := TRUE;
    END_IF;
END_FOR;

// --- PREDICTIVE DIAGNOSTICS ---
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO

    // Pressure drop trend
    IF (L_Prev_Pressure[L_i] > 0.0) AND
       ((L_Prev_Pressure[L_i] - VI_Manifold_Pressures[L_i]) > 0.2) THEN
        GVL_STATE.G_Predictive_Pump_Pressure_Drop[L_i] := TRUE;
    ELSE
        GVL_STATE.G_Predictive_Pump_Pressure_Drop[L_i] := FALSE;
    END_IF;

    // Current rise trend
    IF (L_Prev_Current[L_i] > 0.0) AND
       (VI_Manifold_Currents[L_i] > (L_Prev_Current[L_i] * 1.2)) THEN
        GVL_STATE.G_Predictive_Pump_Current_Rise[L_i] := TRUE;
    ELSE
        GVL_STATE.G_Predictive_Pump_Current_Rise[L_i] := FALSE;
    END_IF;

    // escalate degraded state
    IF GVL_STATE.G_Predictive_Pump_Pressure_Drop[L_i] OR
       GVL_STATE.G_Predictive_Pump_Current_Rise[L_i] THEN
        GVL_STATE.G_Heating_Subsystem_Degraded := TRUE;
    END_IF;

    L_Prev_Pressure[L_i] := VI_Manifold_Pressures[L_i];
    L_Prev_Current[L_i] := VI_Manifold_Currents[L_i];

END_FOR;

// --- rest of logic (boiler etc.) remains unchanged ---

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_System_Manager <<<
