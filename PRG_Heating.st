PROGRAM PRG_Heating

VAR
    L_Last_Mode : INT := 0; // 0=normal, 1=preheat, 2=freeze
    L_Mode_Hold_Timer : FB_System_Timer;
END_VAR

VAR
    fbHeatingManager : FB_Heating_System_Manager;
    fbDHWManager : FB_DHW_Manager;
    fbDiagEventManager : FB_Diagnostics_Event_Manager;
    fbDecision : FB_Heating_Decision_Context;
    fbRootCause : FB_Diagnostics_RootCause;
    fbRootDemandMap : FB_Heating_Demand_Map;
    L_i : INT;
    L_j : INT;
    L_Zone_ID : INT;
    L_Zone_Valves : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF BOOL;
    L_Boiler_Modulation_REAL : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF REAL;
    L_Heating_Emergency_Stop : BOOL;
    L_Heating_Gas_Safety_Stop : BOOL;
    L_Heating_DHW_Demand : BOOL;
    L_Manifold_Adjusted_Priority : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF INT;
    L_Root_Demand_Map : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
END_VAR

// ============================================================
// S1. INPUTS / LOCAL ARBITRATION CONTEXT
// ============================================================

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BOILERS DO
    L_Boiler_Modulation_REAL[L_i] := TO_REAL(GVL_IO.AI_Boiler_Modulation[L_i]);
END_FOR;

L_Heating_Emergency_Stop := GVL_STATE.G_Safety_Emergency_Stop;
L_Heating_Gas_Safety_Stop := GVL_STATE.G_Safety_Gas_Latched;
L_Heating_DHW_Demand := fbDHWManager.VO_Heating_Pump;

IF L_Heating_Emergency_Stop THEN
    L_Heating_Gas_Safety_Stop := FALSE;
    L_Heating_DHW_Demand := FALSE;
ELSIF L_Heating_Gas_Safety_Stop THEN
    L_Heating_DHW_Demand := FALSE;
ELSIF GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_DEGRADED THEN
    L_Heating_DHW_Demand := FALSE;
END_IF;

L_Mode_Hold_Timer(
    IN := TRUE,
    PT := T#30s,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

IF L_Mode_Hold_Timer.Q THEN
    IF GVL_STATE.G_Freeze_Request THEN
        L_Last_Mode := 2;
    ELSIF GVL_STATE.G_Preheat_Request THEN
        L_Last_Mode := 1;
    ELSE
        L_Last_Mode := 0;
    END_IF;
END_IF;

CASE L_Last_Mode OF
    2: GVL_STATE.G_Target_Temperature := 5.0;
    1: GVL_STATE.G_Target_Temperature := 22.0;
    ELSE GVL_STATE.G_Target_Temperature := 20.0;
END_CASE;

// ============================================================
// S1.5 DECISION CONTEXT / THERMAL ALLOCATION
// ============================================================

// === HP-1 + HP-2 PRIORITY BIAS APPLICATION ===
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    L_Manifold_Adjusted_Priority[L_i] := GVL_CONFIG.G_Manifold_Priority[L_i];
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
    L_j := TO_INT(GVL_CONFIG.G_HMI_FloorHeating_Configs[L_i].manifold_id);
    L_Zone_ID := GVL_CONFIG.G_Heating_Circuit_To_Zone[L_i];

    IF (L_j >= 1) AND (L_j <= GVL_CONSTANTS.C_MAX_MANIFOLDS) AND (L_Zone_ID >= 1) AND (L_Zone_ID <= GVL_CONSTANTS.C_MAX_ZONES) THEN

        // Base policy bias (HP-1), mapped circuit -> logical zone
        L_Manifold_Adjusted_Priority[L_j] := L_Manifold_Adjusted_Priority[L_j] + TO_INT(GVL_HEATING_POLICY.G_Zone_Priority_Bias[L_Zone_ID]);

        // Guest preheat boost (HP-2, config-driven), mapped circuit -> logical zone
        IF GVL_HEATING_POLICY_CONFIG.G_Guest_Preheat_Enabled AND GVL_HEATING_POLICY.G_Zone_Guest_Preheat_Request[L_Zone_ID] THEN
            L_Manifold_Adjusted_Priority[L_j] := L_Manifold_Adjusted_Priority[L_j] + GVL_HEATING_POLICY_CONFIG.G_Guest_Preheat_Priority_Boost;
        END_IF;

        // Lower bound
        IF L_Manifold_Adjusted_Priority[L_j] < 1 THEN
            L_Manifold_Adjusted_Priority[L_j] := 1;
        END_IF;

    END_IF;
END_FOR;

fbDecision(
    VI_Manifold_Pump_In_Service := GVL_CONFIG.G_Manifold_Pump_In_Service,
    VI_Manifold_Pressure_Fault := GVL_STATUS.G_Diagnostics.Manifold_Pressure_Fault,
    VI_Manifold_Current_Fault := GVL_STATUS.G_Diagnostics.Manifold_Current_Fault,
    VI_Manifold_Thermal_Weight := GVL_CONFIG.G_Manifold_Thermal_Weight,
    VI_Manifold_Priority := L_Manifold_Adjusted_Priority,
    VI_Max_Thermal_Budget := GVL_CONFIG.G_Max_Thermal_Budget
);

// ============================================================
// S2. HEATING / DHW ORCHESTRATION CALLS
// ============================================================

fbHeatingManager(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_IsActivePLC := GVL_STATUS.G_Is_Active_PLC,
    VI_Outdoor_Temp := GVL_STATE.G_Outdoor_Temp,
    VI_Floor_Temps := GVL_STATE.G_Floor_Temps,
    VI_Room_Temps := GVL_STATE.G_Room_Temps,
    VI_Config := GVL_CONFIG.G_Heating_Config,
    VI_Zone_Configs := GVL_CONFIG.G_HMI_FloorHeating_Configs,
    VI_Tariff := GVL_CONFIG.G_HMI_Tariff_Settings,
    VI_Current_Hour := TO_UINT(GVL_STATUS.G_Time_Of_Day_MS / GVL_CONSTANTS.C_MS_IN_HOUR),
    VI_Manifold_Pressures := GVL_STATE.G_Manifold_Pressures,
    VI_Manifold_Currents := GVL_STATE.G_Manifold_Currents,
    VI_Manifold_Temps_Supply := GVL_STATE.G_Manifold_T_Supply,
    VI_Manifold_Temps_Return := GVL_STATE.G_Manifold_T_Return,
    VI_Boiler_Flame_Status := GVL_STATE.G_Boiler_Flame,
    VI_Boiler_Error_Status := GVL_STATE.G_Boiler_Error,
    VI_Boiler_OT_Online := GVL_STATE.G_Boiler_OT_Online,
    VI_Boiler_Modulation := L_Boiler_Modulation_REAL,
    VI_Rule_Actions := GVL_STATE.G_Rule_Actions,
    VI_IO_Modules_Online := GVL_STATUS.G_IO_Modules_Online,
    VI_DHW_Heating_Demand := L_Heating_DHW_Demand,
    VI_DHW_Target_Temp := GVL_CONFIG.G_DHW_Config.Target_Temp,
    VI_System_Mode := GVL_STATE.G_System_Mode,
    VI_Emergency_Stop := L_Heating_Emergency_Stop,
    VI_Gas_Safety_Stop := L_Heating_Gas_Safety_Stop,
    VI_Manifold_End_Switches := GVL_STATE.G_Manifold_End_Switches,
    VI_Valve_Test_Config := GVL_CONFIG.G_Valve_Test_Config,
    VO_Manifold_Valves => GVL_STATE.G_Manifold_Valves,
    VO_Manifold_Pumps => GVL_STATE.G_Manifold_Pumps,
    VO_Zone_Valves => L_Zone_Valves,
    VO_Boiler_OT_Enable => GVL_STATE.G_Boiler_OT_Enable,
    VO_Boiler_OT_Setpoint => GVL_STATE.G_Boiler_OT_Setpoint,
    VO_Backup_Circulation_Pump => GVL_STATE.G_Backup_Circulation_Pump,
    VO_Electric_Heater_Enable => GVL_STATE.G_Electric_Heater_Enable,
    VO_Freeze_Risk_Status => GVL_STATE.G_Safety_Freeze_Risk,
    VO_Status => GVL_STATUS.G_Manifold_Status,
    VO_Boiler_Status => GVL_STATUS.G_Boiler_Status
);

// Apply global and thermal allocation constraints after base heating orchestration.
// Coordinator owns cross-subsystem blocking; decision context owns eligibility/budget.
// Heating manager remains the control algorithm owner.
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    IF GVL_SYSTEM_COORDINATION.G_Block_Heating OR (NOT fbDecision.VO_Manifold_Enabled[L_i]) THEN
        GVL_STATE.G_Manifold_Pumps[L_i] := FALSE;
        GVL_STATE.G_Manifold_Valves[L_i] := 0.0;

        FOR L_j := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
            IF GVL_CONFIG.G_HMI_FloorHeating_Configs[L_j].manifold_id = L_i THEN
                L_Zone_Valves[L_j] := FALSE;
            END_IF;
        END_FOR;
    END_IF;
END_FOR;

fbDHWManager(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Current_TOD := GVL_STATUS.G_Current_TOD,
    VI_IsActivePLC := GVL_STATUS.G_Is_Active_PLC,
    VI_Temp := GVL_STATE.G_DHW_Temp,
    VI_Pressure := GVL_STATE.G_DHW_Pressure,
    VI_Config := GVL_CONFIG.G_DHW_Config,
    VI_Current_Day_Of_Week := GVL_STATUS.G_Current_Day,
    VI_IO_Modules_Online := GVL_STATUS.G_IO_Modules_Online,
    VI_Reset_Errors := GVL_INTENT_USER.I_Reset_Errors,
    VI_Emergency_Stop := GVL_STATE.G_Safety_Emergency_Stop,
    VI_System_Mode := GVL_STATE.G_System_Mode,
    VO_Heating_Pump => GVL_STATE.G_DHW_Heating_Pump,
    VO_Circ_Pump => GVL_STATE.G_DHW_Circ_Pump,
    VO_Status => GVL_STATUS.G_DHW_Status
);

// ============================================================
// S3. DIAGNOSTICS PROJECTION + EVENTS
// ============================================================

GVL_STATUS.G_Diagnostics.Backup_Pump_Out_Of_Service := NOT GVL_CONFIG.G_Backup_Circulation_Pump_In_Service;
GVL_STATUS.G_Diagnostics.Electric_Heater_Out_Of_Service := NOT GVL_CONFIG.G_Electric_Heater_In_Service;

fbDiagEventManager(
    VI_Code := GVL_CONFIG.ERR_BACKUP_PUMP_OUT_OF_SERVICE,
    VI_Severity := 2,
    VI_Active := NOT GVL_CONFIG.G_Backup_Circulation_Pump_In_Service,
    VI_Timestamp := GVL_STATUS.G_System_Time_MS,
    VI_Source := 400,
    VIO_Events := GVL_STATUS.G_Diagnostics_Events,
    VIO_Count := GVL_STATUS.G_Diagnostics_Count
);

fbDiagEventManager(
    VI_Code := GVL_CONFIG.ERR_ELECTRIC_HEATER_OUT_OF_SERVICE,
    VI_Severity := 2,
    VI_Active := NOT GVL_CONFIG.G_Electric_Heater_In_Service,
    VI_Timestamp := GVL_STATUS.G_System_Time_MS,
    VI_Source := 401,
    VIO_Events := GVL_STATUS.G_Diagnostics_Events,
    VIO_Count := GVL_STATUS.G_Diagnostics_Count
);

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    GVL_STATUS.G_Diagnostics.Manifold_Pump_Out_Of_Service[L_i] := NOT GVL_CONFIG.G_Manifold_Pump_In_Service[L_i];

    fbDiagEventManager(
        VI_Code := GVL_CONFIG.ERR_MANIFOLD_PUMP_OUT_OF_SERVICE,
        VI_Severity := 2,
        VI_Active := NOT GVL_CONFIG.G_Manifold_Pump_In_Service[L_i],
        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
        VI_Source := 410 + L_i,
        VIO_Events := GVL_STATUS.G_Diagnostics_Events,
        VIO_Count := GVL_STATUS.G_Diagnostics_Count
    );
END_FOR;

GVL_STATUS.G_Diagnostics.DHW_Heating_Pump_Out_Of_Service := NOT GVL_CONFIG.G_DHW_Heating_Pump_In_Service;
GVL_STATUS.G_Diagnostics.DHW_Circ_Pump_Out_Of_Service := NOT GVL_CONFIG.G_DHW_Circ_Pump_In_Service;

fbDiagEventManager(
    VI_Code := GVL_CONFIG.ERR_DHW_HEATING_PUMP_OUT_OF_SERVICE,
    VI_Severity := 2,
    VI_Active := NOT GVL_CONFIG.G_DHW_Heating_Pump_In_Service,
    VI_Timestamp := GVL_STATUS.G_System_Time_MS,
    VI_Source := 420,
    VIO_Events := GVL_STATUS.G_Diagnostics_Events,
    VIO_Count := GVL_STATUS.G_Diagnostics_Count
);

fbDiagEventManager(
    VI_Code := GVL_CONFIG.ERR_DHW_CIRC_PUMP_OUT_OF_SERVICE,
    VI_Severity := 2,
    VI_Active := NOT GVL_CONFIG.G_DHW_Circ_Pump_In_Service,
    VI_Timestamp := GVL_STATUS.G_System_Time_MS,
    VI_Source := 421,
    VIO_Events := GVL_STATUS.G_Diagnostics_Events,
    VIO_Count := GVL_STATUS.G_Diagnostics_Count
);

fbDiagEventManager(
    VI_Code := GVL_CONFIG.ERR_FREEZE_HARDWARE_FAILED,
    VI_Severity := 4,
    VI_Active := GVL_STATE.G_Freeze_Hardware_Failed,
    VI_Timestamp := GVL_STATUS.G_System_Time_MS,
    VI_Source := 430,
    VIO_Events := GVL_STATUS.G_Diagnostics_Events,
    VIO_Count := GVL_STATUS.G_Diagnostics_Count
);

// ============================================================
// S4. MAINTENANCE GATING
// ============================================================

IF NOT GVL_CONFIG.G_Backup_Circulation_Pump_In_Service THEN
    GVL_STATE.G_Backup_Circulation_Pump := FALSE;
END_IF;
IF NOT GVL_CONFIG.G_Electric_Heater_In_Service THEN
    GVL_STATE.G_Electric_Heater_Enable := FALSE;
END_IF;
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    IF NOT GVL_CONFIG.G_Manifold_Pump_In_Service[L_i] THEN
        GVL_STATE.G_Manifold_Pumps[L_i] := FALSE;
    END_IF;
END_FOR;
IF NOT GVL_CONFIG.G_DHW_Heating_Pump_In_Service THEN
    GVL_STATE.G_DHW_Heating_Pump := FALSE;
END_IF;
IF NOT GVL_CONFIG.G_DHW_Circ_Pump_In_Service THEN
    GVL_STATE.G_DHW_Circ_Pump := FALSE;
END_IF;

// ============================================================
// S5. FREEZE HARDWARE SUPPORT LOGIC
// ============================================================

GVL_STATE.G_Freeze_Hardware_Degraded := GVL_STATUS.G_Diagnostics.Backup_Pump_Fault OR GVL_STATUS.G_Diagnostics.Electric_Heater_Fault;
GVL_STATE.G_Freeze_Hardware_Failed := GVL_STATUS.G_Diagnostics.Backup_Pump_Fault AND GVL_STATUS.G_Diagnostics.Electric_Heater_Fault;
IF GVL_STATE.G_Freeze_Hardware_Failed THEN
    GVL_STATE.G_Backup_Circulation_Pump := FALSE;
    GVL_STATE.G_Electric_Heater_Enable := FALSE;
    GVL_STATE.G_Safety_Freeze_Risk := TRUE;
END_IF;

// >>> BULK_SYNC_ANCHOR: PRG_Heating <<<

// ============================================================
// S6. ADAPTER COPY-OUT
// ============================================================

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
    GVL_STATE.G_Zone_Valves[L_i] := L_Zone_Valves[L_i];
END_FOR;

// ============================================================
// S7. ROOT CAUSE DIAGNOSTICS
// ============================================================

fbRootDemandMap(
    VI_Zone_Valves := L_Zone_Valves,
    VI_Zone_Configs := GVL_CONFIG.G_HMI_FloorHeating_Configs,
    VO_Manifold_Demand_Map => L_Root_Demand_Map
);

fbRootCause(
    VI_Emergency_Stop := GVL_STATE.G_Safety_Emergency_Stop,
    VI_Gas_Safety := GVL_STATE.G_Safety_Gas_Latched,
    VI_IO_Failsafe := GVL_STATE.G_Heating_IO_Fault,
    VI_Boiler_OT_Online := GVL_STATE.G_Boiler_OT_Online,
    VI_Boiler_Error := GVL_STATE.G_Boiler_Error,
    VI_Boiler_Flame := GVL_STATE.G_Boiler_Flame,
    VI_Manifold_Pumps := GVL_STATE.G_Manifold_Pumps,
    VI_Manifold_Valves := GVL_STATE.G_Manifold_Valves,
    VI_Sensor_Error := GVL_STATE.G_Heating_Sensor_Fault,
    VI_Supply_Temps := GVL_STATE.G_Manifold_T_Supply,
    VI_Target_Supply := GVL_CONFIG.G_Heating_Config.Target_Floor_Temp,
    VI_Demand_Map := L_Root_Demand_Map
);

GVL_STATE.G_Heating_RootCause := fbRootCause.VO_RootCause;
GVL_STATE.G_Heating_RootConfidence := fbRootCause.VO_Confidence;
