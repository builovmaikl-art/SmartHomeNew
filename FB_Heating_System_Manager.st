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
    L_j : INT;
    L_Target_Supply_Temp : REAL;
    L_Zone_Active_Map : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    fbValveTestManager : FB_Valve_Test_Manager;
    L_IO_Failsafe_Active : BOOL;
    L_Freeze_Active : BOOL;
    L_Freeze_Target_Supply : REAL;
    L_Min_Supply_Temp : REAL;
    L_Policy_Degraded : BOOL;
    L_Sensor_Error : BOOL;
    L_Subsys_Degraded : BOOL;
    fbAdaptiveTarget : FB_Heating_Adaptive_Target;
    fbSafetyGate : FB_Heating_Safety_Gate;
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

VO_Backup_Circulation_Pump := FALSE;
VO_Electric_Heater_Enable := FALSE;
VO_Freeze_Risk_Status := FALSE;

IF fbSafetyGate.VO_Block_Normal_Heating THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
        VO_Zone_Valves[L_i] := FALSE;
    END_FOR;

    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
        IF fbSafetyGate.VO_IO_Failsafe_Active AND L_Freeze_Active THEN
            VO_Manifold_Pumps[L_i] := TRUE;
            VO_Manifold_Valves[L_i] := 35.0;
        ELSE
            VO_Manifold_Pumps[L_i] := FALSE;
            VO_Manifold_Valves[L_i] := 0.0;
        END_IF;
    END_FOR;

    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BOILERS DO
        VO_Boiler_OT_Enable[L_i] := FALSE;
        VO_Boiler_OT_Setpoint[L_i] := 0.0;
        VO_Boiler_Status[L_i].Warning := FALSE;
        VO_Boiler_Status[L_i].Error := TRUE;
    END_FOR;

    IF fbSafetyGate.VO_Gas_Safety_Active AND L_Freeze_Active THEN
        VO_Backup_Circulation_Pump := TRUE;
        L_Min_Supply_Temp := 1000.0;
        FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
            IF VI_Manifold_Temps_Supply[L_i] < L_Min_Supply_Temp THEN
                L_Min_Supply_Temp := VI_Manifold_Temps_Supply[L_i];
            END_IF;
        END_FOR;
        IF L_Min_Supply_Temp > 900.0 THEN
            L_Min_Supply_Temp := 0.0;
        END_IF;

        IF L_Min_Supply_Temp < (L_Freeze_Target_Supply - 1.0) THEN
            VO_Electric_Heater_Enable := TRUE;
        ELSIF L_Min_Supply_Temp > (L_Freeze_Target_Supply + 1.0) THEN
            VO_Electric_Heater_Enable := FALSE;
        END_IF;
        VO_Freeze_Risk_Status := TRUE;
    END_IF;

    IF fbSafetyGate.VO_IO_Failsafe_Active AND L_Freeze_Active THEN
        IF VI_Boiler_OT_Online[1] AND NOT VI_Boiler_Error_Status[1] THEN
            VO_Boiler_OT_Enable[1] := TRUE;
            VO_Boiler_OT_Setpoint[1] := L_Freeze_Target_Supply;
        END_IF;
    END_IF;

    RETURN;
END_IF;

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
    VI_Scenario_Adjust := 0.0,
    VI_Zone_Configs := VI_Zone_Configs,
    VI_Floor_Temps := VI_Floor_Temps,
    VI_Room_Temps := VI_Room_Temps,
    VI_Rule_Actions := VI_Rule_Actions,
    VO_Zone_Valves => VO_Zone_Valves,
    VO_Heating_Sensor_Fault => L_Sensor_Error
);

GVL_STATE.G_Heating_Sensor_Fault := L_Sensor_Error;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    L_Zone_Active_Map[L_i] := FALSE;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
    IF VO_Zone_Valves[L_i] THEN
        L_j := VI_Zone_Configs[L_i].manifold_id;
        IF L_j >= 1 AND L_j <= GVL_CONSTANTS.C_MAX_MANIFOLDS THEN
            L_Zone_Active_Map[L_j] := TRUE;
        END_IF;
    END_IF;
END_FOR;

fbManifoldControl(
    VI_System_Time_MS := VI_System_Time_MS,
    VI_IsActivePLC := VI_IsActivePLC,
    VI_DHW_Heating_Demand := VI_DHW_Heating_Demand,
    VI_Freeze_Mode_Active := L_Freeze_Active,
    VI_Target_Supply_Temp := L_Target_Supply_Temp,
    VI_Any_Zone_Active := L_Zone_Active_Map,
    VI_Manifold_Pressures := VI_Manifold_Pressures,
    VI_Manifold_Currents := VI_Manifold_Currents,
    VI_Manifold_Temps_Supply := VI_Manifold_Temps_Supply,
    VI_Manifold_Temps_Return := VI_Manifold_Temps_Return,
    VO_Manifold_Pumps => VO_Manifold_Pumps,
    VO_Manifold_Valves => VO_Manifold_Valves,
    VO_Status => VO_Status
);

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
            VO_Manifold_Valves[L_i] := 100.0;
        ELSE
            VO_Manifold_Valves[L_i] := 0.0;
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

GVL_STATE.G_Heating_Subsystem_Degraded := L_Subsys_Degraded;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_System_Manager <<<
