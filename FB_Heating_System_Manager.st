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
    VI_Room_Temps : ARRAY[1..GVL_CONSTANTS.C_MAX_ZONES] OF REAL;
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
    L_Manifold_Demand_Filtered : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    L_Manifold_Available : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    L_Manifold_In_Service : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    L_Manifold_Subsystem_Degraded : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    L_Manifold_Base_Priority : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF INT;
    L_Manifold_Thermal_Weight : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL;
    L_Allocation_Degraded : BOOL;
    fbValveTestManager : FB_Valve_Test_Manager;
    L_IO_Failsafe_Active : BOOL;
    L_Freeze_Active : BOOL;
    L_Freeze_Target_Supply : REAL;
    L_Policy_Degraded : BOOL;
    L_Sensor_Error : BOOL;
    L_Subsys_Degraded : BOOL;
    L_Pressure_OK : BOOL;
    L_Prev_Pressure : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL;
    L_Prev_Current : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL;
    L_Error_Instant : REAL;
    L_Confidence : REAL;
    fbAdaptiveTarget : FB_Heating_Adaptive_Target;
    fbSafetyGate : FB_Heating_Safety_Gate;
    fbSafeState : FB_Heating_Safe_State;
    fbDemandMap : FB_Heating_Demand_Map;
    fbAllocationFilter : FB_Heating_Allocation_Filter;
    fbCircuitControl : FB_Heating_Circuit_Control;
    fbManifoldControl : FB_Heating_Manifold_Control;
    fbBoilerControl : FB_Heating_Boiler_Control;
END_VAR

L_Policy_Degraded := (VI_System_Mode = E_System_Operating_Mode.MODE_DEGRADED);

GVL_STATE.G_Heating_IO_Fault := FALSE;
GVL_STATE.G_Heating_Sensor_Fault := FALSE;
GVL_STATE.G_Heating_Subsystem_Degraded := FALSE;
L_Sensor_Error := FALSE;
L_Subsys_Degraded := FALSE;
L_Allocation_Degraded := FALSE;

L_IO_Failsafe_Active := FALSE;
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MODULES DO
    IF NOT VI_IO_Modules_Online[L_i] THEN
        L_IO_Failsafe_Active := TRUE;
        GVL_STATE.G_Heating_IO_Fault := TRUE;
        GVL_STATE.G_Heating_Subsystem_Degraded := TRUE;
        EXIT;
    END_IF;
END_FOR;

fbSafetyGate(
    VI_System_Mode := VI_System_Mode,
    VI_Emergency_Stop := VI_Emergency_Stop,
    VI_Gas_Safety_Stop := VI_Gas_Safety_Stop,
    VI_IO_Failsafe_Active := L_IO_Failsafe_Active,
    VI_Outdoor_Temp := VI_Outdoor_Temp,
    VI_Freeze_Threshold := VI_Config.Freeze_Threshold,
    VI_Floor_Temps := VI_Floor_Temps,
    VO_Freeze_Mode_Active => L_Freeze_Active,
    VO_Freeze_Target_Supply => L_Freeze_Target_Supply
);

fbSafeState(
    VI_Block_Normal_Heating := fbSafetyGate.VO_Block_Normal_Heating,
    VI_IO_Failsafe_Active := fbSafetyGate.VO_IO_Failsafe_Active,
    VI_Gas_Safety_Active := fbSafetyGate.VO_Gas_Safety_Active,
    VI_Freeze_Active := L_Freeze_Active,
    VI_Freeze_Target_Supply := L_Freeze_Target_Supply,
    VI_Manifold_Temps_Supply := VI_Manifold_Temps_Supply,
    VI_Boiler_Error_Status := VI_Boiler_Error_Status,
    VI_Boiler_OT_Online := VI_Boiler_OT_Online
);

IF fbSafeState.VO_Applied THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
        VO_Zone_Valves[L_i] := fbSafeState.VO_Zone_Valves[L_i];
    END_FOR;

    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
        VO_Manifold_Pumps[L_i] := fbSafeState.VO_Manifold_Pumps[L_i];
        VO_Manifold_Valves[L_i] := fbSafeState.VO_Manifold_Valves[L_i];
    END_FOR;

    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BOILERS DO
        VO_Boiler_OT_Enable[L_i] := fbSafeState.VO_Boiler_OT_Enable[L_i];
        VO_Boiler_OT_Setpoint[L_i] := fbSafeState.VO_Boiler_OT_Setpoint[L_i];
        VO_Boiler_Status[L_i] := fbSafeState.VO_Boiler_Status[L_i];
    END_FOR;

    VO_Backup_Circulation_Pump := fbSafeState.VO_Backup_Circulation_Pump;
    VO_Electric_Heater_Enable := fbSafeState.VO_Electric_Heater_Enable;
    VO_Freeze_Risk_Status := fbSafeState.VO_Freeze_Risk_Status;
    RETURN;
END_IF;

VO_Backup_Circulation_Pump := FALSE;
VO_Electric_Heater_Enable := FALSE;
VO_Freeze_Risk_Status := FALSE;

IF L_Freeze_Active THEN
    L_Target_Supply_Temp := L_Freeze_Target_Supply;
ELSE
    L_Target_Supply_Temp := VI_Config.Target_Floor_Temp;
END_IF;

fbAdaptiveTarget(
    VI_Base_Target_Supply_Temp := L_Target_Supply_Temp,
    VI_Global_Target_Temperature := GVL_STATE.G_Target_Temperature,
    VI_Zone_Configs := VI_Zone_Configs,
    VI_Floor_Temps := VI_Floor_Temps,
    VI_Room_Temps := VI_Room_Temps,
    VO_Target_Supply_Temp => L_Target_Supply_Temp
);

fbCircuitControl(
    VI_System_Time_MS := VI_System_Time_MS,
    VI_Current_Hour := VI_Current_Hour,
    VI_IsActivePLC := VI_IsActivePLC,
    VI_Config := VI_Config,
    VI_Tariff := VI_Tariff,
    VI_Scenario_Adjust := REAL#0.0,
    VI_Zone_Configs := VI_Zone_Configs,
    VI_Floor_Temps := VI_Floor_Temps,
    VI_Room_Temps := VI_Room_Temps,
    VI_Rule_Actions := VI_Rule_Actions,
    VO_Zone_Valves => VO_Zone_Valves,
    VO_Heating_Sensor_Fault => L_Sensor_Error
);

GVL_STATE.G_Heating_Sensor_Fault := L_Sensor_Error;

fbDemandMap(
    VI_Zone_Valves := VO_Zone_Valves,
    VI_Zone_Configs := VI_Zone_Configs,
    VO_Manifold_Demand_Map => L_Manifold_Demand_Map
);

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    L_Manifold_Available[L_i] := VI_Manifold_Pressures[L_i] >= GVL_CONSTANTS.C_MIN_HEATING_MANIFOLD_PRESSURE;
    L_Manifold_In_Service[L_i] := GVL_CONFIG.G_Manifold_Pump_In_Service[L_i];
    L_Manifold_Subsystem_Degraded[L_i] :=
        GVL_STATE.G_Predictive_Pump_Pressure_Drop[L_i]
        OR GVL_STATE.G_Predictive_Pump_Current_Rise[L_i];

    L_Manifold_Base_Priority[L_i] := GVL_CONFIG.G_Manifold_Priority[L_i];
    L_Manifold_Thermal_Weight[L_i] := GVL_CONFIG.G_Manifold_Thermal_Weight[L_i];
END_FOR;

fbAllocationFilter(
    VI_Enable := TRUE,
    VI_Enable_Policy_Allocation := FALSE,
    VI_Freeze_Mode_Active := L_Freeze_Active,
    VI_DHW_Heating_Demand := VI_DHW_Heating_Demand,
    VI_Manifold_Demand_Map := L_Manifold_Demand_Map,
    VI_Manifold_Available := L_Manifold_Available,
    VI_Manifold_In_Service := L_Manifold_In_Service,
    VI_Manifold_Subsystem_Degraded := L_Manifold_Subsystem_Degraded,
    VI_Manifold_Base_Priority := L_Manifold_Base_Priority,
    VI_Manifold_Thermal_Weight := L_Manifold_Thermal_Weight,
    VI_Max_Thermal_Budget := GVL_CONFIG.G_Max_Thermal_Budget,
    VO_Manifold_Demand_Filtered => L_Manifold_Demand_Filtered,
    VO_Allocation_Degraded => L_Allocation_Degraded
);

IF L_Allocation_Degraded THEN
    GVL_STATE.G_Heating_Subsystem_Degraded := TRUE;
END_IF;

fbManifoldControl(
    VI_System_Time_MS := VI_System_Time_MS,
    VI_IsActivePLC := VI_IsActivePLC,
    VI_DHW_Heating_Demand := VI_DHW_Heating_Demand,
    VI_Freeze_Mode_Active := L_Freeze_Active,
    VI_Target_Supply_Temp := L_Target_Supply_Temp,
    VI_Any_Zone_Active := L_Manifold_Demand_Filtered,
    VI_Manifold_Pressures := VI_Manifold_Pressures,
    VI_Manifold_Currents := VI_Manifold_Currents,
    VI_Manifold_Temps_Supply := VI_Manifold_Temps_Supply,
    VI_Manifold_Temps_Return := VI_Manifold_Temps_Return,
    VO_Manifold_Pumps => VO_Manifold_Pumps,
    VO_Manifold_Valves => VO_Manifold_Valves,
    VO_Status => VO_Status
);

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    L_Pressure_OK := VI_Manifold_Pressures[L_i] >= GVL_CONSTANTS.C_MIN_HEATING_MANIFOLD_PRESSURE;

    IF VO_Manifold_Pumps[L_i] AND NOT L_Pressure_OK THEN
        VO_Manifold_Pumps[L_i] := FALSE;
        GVL_STATE.G_Heating_Subsystem_Degraded := TRUE;
    END_IF;

    IF (L_Prev_Pressure[L_i] > REAL#0.0) AND ((L_Prev_Pressure[L_i] - VI_Manifold_Pressures[L_i]) > REAL#0.2) THEN
        GVL_STATE.G_Predictive_Pump_Pressure_Drop[L_i] := TRUE;
    ELSE
        GVL_STATE.G_Predictive_Pump_Pressure_Drop[L_i] := FALSE;
    END_IF;

    IF (L_Prev_Current[L_i] > REAL#0.0) AND (VI_Manifold_Currents[L_i] > (L_Prev_Current[L_i] * REAL#1.2)) THEN
        GVL_STATE.G_Predictive_Pump_Current_Rise[L_i] := TRUE;
    ELSE
        GVL_STATE.G_Predictive_Pump_Current_Rise[L_i] := FALSE;
    END_IF;

    IF GVL_STATE.G_Predictive_Pump_Pressure_Drop[L_i] OR GVL_STATE.G_Predictive_Pump_Current_Rise[L_i] THEN
        GVL_STATE.G_Heating_Subsystem_Degraded := TRUE;
    END_IF;

    L_Prev_Pressure[L_i] := VI_Manifold_Pressures[L_i];
    L_Prev_Current[L_i] := VI_Manifold_Currents[L_i];
END_FOR;

L_Error_Instant := REAL#0.0;

IF GVL_STATE.G_Heating_Sensor_Fault THEN
    L_Error_Instant := L_Error_Instant + REAL#0.2;
END_IF;

IF GVL_STATE.G_Heating_IO_Fault THEN
    L_Error_Instant := L_Error_Instant + REAL#0.2;
END_IF;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    IF VI_Manifold_Pressures[L_i] < GVL_CONSTANTS.C_MIN_HEATING_MANIFOLD_PRESSURE THEN
        L_Error_Instant := L_Error_Instant + REAL#0.1;
        EXIT;
    END_IF;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    IF GVL_STATE.G_Predictive_Pump_Pressure_Drop[L_i] OR GVL_STATE.G_Predictive_Pump_Current_Rise[L_i] THEN
        L_Error_Instant := L_Error_Instant + REAL#0.2;
        EXIT;
    END_IF;
END_FOR;

GVL_STATE.G_Heating_Error_Score := (GVL_STATE.G_Heating_Error_Score * REAL#0.98) + L_Error_Instant;
L_Confidence := REAL#1.0 - GVL_STATE.G_Heating_Error_Score;

IF L_Confidence < REAL#0.0 THEN
    L_Confidence := REAL#0.0;
ELSIF L_Confidence > REAL#1.0 THEN
    L_Confidence := REAL#1.0;
END_IF;

GVL_STATE.G_Heating_Confidence := L_Confidence;

GVL_STATE.G_Heating_Confidence_Reason_Code := 0;
GVL_STATE.G_Heating_Confidence_Reason_Text := 'OK';

IF GVL_STATE.G_Heating_IO_Fault THEN
    GVL_STATE.G_Heating_Confidence_Reason_Code := 2;
    GVL_STATE.G_Heating_Confidence_Reason_Text := 'IO fault detected';
ELSIF GVL_STATE.G_Heating_Sensor_Fault THEN
    GVL_STATE.G_Heating_Confidence_Reason_Code := 1;
    GVL_STATE.G_Heating_Confidence_Reason_Text := 'Sensor fault detected';
ELSE
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
        IF VI_Manifold_Pressures[L_i] < GVL_CONSTANTS.C_MIN_HEATING_MANIFOLD_PRESSURE THEN
            GVL_STATE.G_Heating_Confidence_Reason_Code := 3;
            GVL_STATE.G_Heating_Confidence_Reason_Text := 'Low manifold pressure';
            EXIT;
        END_IF;
    END_FOR;

    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
        IF GVL_STATE.G_Predictive_Pump_Pressure_Drop[L_i] OR GVL_STATE.G_Predictive_Pump_Current_Rise[L_i] THEN
            GVL_STATE.G_Heating_Confidence_Reason_Code := 4;
            GVL_STATE.G_Heating_Confidence_Reason_Text := 'Predictive pump degradation';
            EXIT;
        END_IF;
    END_FOR;
END_IF;

IF GVL_STATE.G_Heating_Confidence < REAL#0.5 THEN
    L_Target_Supply_Temp := L_Target_Supply_Temp - REAL#3.0;
END_IF;

CASE GVL_STATE.G_Heating_Confidence_Reason_Code OF
    1:
        L_Target_Supply_Temp := LIMIT(GVL_CONSTANTS.C_BOILER_SETPOINT_MIN, REAL#40.0, GVL_CONSTANTS.C_BOILER_SETPOINT_MAX);
    2:
        VO_Backup_Circulation_Pump := TRUE;
    3:
        FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
            VO_Manifold_Pumps[L_i] := FALSE;
        END_FOR;
    4:
        L_Target_Supply_Temp := LIMIT(GVL_CONSTANTS.C_BOILER_SETPOINT_MIN, L_Target_Supply_Temp - REAL#5.0, GVL_CONSTANTS.C_BOILER_SETPOINT_MAX);
ELSE
    // no auto-recovery action
END_CASE;

fbValveTestManager(
    VI_System_Time_MS := VI_System_Time_MS,
    VI_IsActivePLC := VI_IsActivePLC,
    VI_Valve_Currents := VI_Manifold_Currents,
    VI_Valve_End_Switches := VI_Manifold_End_Switches,
    VI_Config := VI_Valve_Test_Config
);

IF fbValveTestManager.VO_Test_Active THEN
    L_i := fbValveTestManager.VO_Current_Valve;
    IF L_i >= 1 AND L_i <= GVL_CONSTANTS.C_MAX_MANIFOLDS THEN
        IF fbValveTestManager.VO_Valve_Cmd[L_i] THEN
            VO_Manifold_Valves[L_i] := REAL#100.0;
        ELSE
            VO_Manifold_Valves[L_i] := REAL#0.0;
        END_IF;
        VO_Manifold_Pumps[L_i] := FALSE;
    END_IF;
END_IF;

fbBoilerControl(
    VI_System_Time_MS := VI_System_Time_MS,
    VI_IsActivePLC := VI_IsActivePLC,
    VI_DHW_Heating_Demand := VI_DHW_Heating_Demand,
    VI_DHW_Target_Temp := VI_DHW_Target_Temp,
    VI_Target_Supply_Temp := L_Target_Supply_Temp,
    VI_Freeze_Mode_Active := L_Freeze_Active,
    VI_Policy_Degraded := L_Policy_Degraded,
    VI_Manifold_Pumps := VO_Manifold_Pumps,
    VI_Manifold_Valves := VO_Manifold_Valves,
    VI_Boiler_Flame_Status := VI_Boiler_Flame_Status,
    VI_Boiler_Error_Status := VI_Boiler_Error_Status,
    VI_Boiler_OT_Online := VI_Boiler_OT_Online,
    VI_Boiler_Modulation := VI_Boiler_Modulation,
    VO_Boiler_OT_Enable => VO_Boiler_OT_Enable,
    VO_Boiler_OT_Setpoint => VO_Boiler_OT_Setpoint,
    VO_Boiler_Status => VO_Boiler_Status,
    VO_Any_Subsystem_Degraded => L_Subsys_Degraded
);

GVL_STATE.G_Heating_Subsystem_Degraded := GVL_STATE.G_Heating_Subsystem_Degraded OR L_Subsys_Degraded;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_System_Manager <<<
