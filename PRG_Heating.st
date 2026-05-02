PROGRAM PRG_Heating

VAR
    fbLocalContext : FB_Heating_Local_Context;
    fbThermalAllocation : FB_Heating_Thermal_Allocation;
    fbHeatingOrchestration : FB_Heating_Orchestration;
    fbHeatingDiagnostics : FB_Heating_Diagnostics;
    fbHeatingMaintenanceGating : FB_Heating_Maintenance_Gating;
    fbHeatingFreezeHardware : FB_Heating_Freeze_Hardware;
    fbHeatingRootCauseDiagnostics : FB_Heating_RootCause_Diagnostics;
    fbOutputProjection : FB_Heating_Output_Projection;

    L_i : INT;

    // NORMALIZED INPUTS
    L_Outdoor_Temp : REAL;
    L_Room_Temps : ARRAY[1..GVL_CONSTANTS.C_MAX_ZONES] OF REAL;
    L_Floor_Temps : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF REAL;
    L_Manifold_Pressures : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL;

    // Local actuator buffers
    L_Zone_Valves : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF BOOL;
    L_Manifold_Pumps : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    L_Manifold_Valves : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL;
    L_Boiler_OT_Enable : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF BOOL;
    L_Boiler_OT_Setpoint : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF REAL;
    L_Backup_Circulation_Pump : BOOL;
    L_Electric_Heater_Enable : BOOL;
    L_Freeze_Risk_Status : BOOL;
    L_Manifold_Status : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF ST_Manifold_Status;
    L_Boiler_Status : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF ST_Boiler_Status;
    L_DHW_Heating_Pump : BOOL;
    L_DHW_Circ_Pump : BOOL;
    L_DHW_Status : ST_DHW_Status;
END_VAR

// ========================
// INPUT NORMALIZATION
// ========================

// Outdoor
IF IS_REAL_VALID(GVL_STATE.G_Outdoor_Temp) THEN
    L_Outdoor_Temp := LIMIT(-50.0, GVL_STATE.G_Outdoor_Temp, 60.0);
ELSE
    L_Outdoor_Temp := 0.0;
END_IF;

// Room
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_ZONES DO
    IF IS_REAL_VALID(GVL_STATE.G_Room_Temps[L_i]) AND
       (GVL_STATE.G_Room_Temps[L_i] > -50.0) AND
       (GVL_STATE.G_Room_Temps[L_i] < 100.0) THEN
        L_Room_Temps[L_i] := GVL_STATE.G_Room_Temps[L_i];
    ELSE
        L_Room_Temps[L_i] := 20.0;
    END_IF;
END_FOR;

// Floor
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
    IF IS_REAL_VALID(GVL_STATE.G_Floor_Temps[L_i]) AND
       (GVL_STATE.G_Floor_Temps[L_i] > -50.0) AND
       (GVL_STATE.G_Floor_Temps[L_i] < 100.0) THEN
        L_Floor_Temps[L_i] := GVL_STATE.G_Floor_Temps[L_i];
    ELSE
        L_Floor_Temps[L_i] := 20.0;
    END_IF;
END_FOR;

// Pressure
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    IF IS_REAL_VALID(GVL_STATE.G_Manifold_Pressures[L_i]) AND
       (GVL_STATE.G_Manifold_Pressures[L_i] > 0.1) THEN
        L_Manifold_Pressures[L_i] := GVL_STATE.G_Manifold_Pressures[L_i];
    ELSE
        L_Manifold_Pressures[L_i] := 0.0;
    END_IF;
END_FOR;

// ========================
// SAFE INIT
// ========================

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
    L_Zone_Valves[L_i] := FALSE;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    L_Manifold_Pumps[L_i] := FALSE;
    L_Manifold_Valves[L_i] := 0.0;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BOILERS DO
    L_Boiler_OT_Enable[L_i] := FALSE;
    L_Boiler_OT_Setpoint[L_i] := 0.0;
END_FOR;

L_Backup_Circulation_Pump := FALSE;
L_Electric_Heater_Enable := FALSE;
L_DHW_Heating_Pump := FALSE;
L_DHW_Circ_Pump := FALSE;

// ========================
// CORE
// ========================

fbLocalContext(
    VI_System_Time_MS := GVL_TIME_SERVICE.G_Now_MS,
    VI_Heating_Emergency_Stop := GVL_COMMAND_SHADOW.G_Heating_Emergency_Stop,
    VI_Heating_Gas_Safety_Stop := GVL_COMMAND_SHADOW.G_Heating_Gas_Safety_Stop,
    VI_DHW_Block := GVL_COMMAND_SHADOW.G_Heating_DHW_Block,
    VI_Freeze_Request := GVL_STATE.G_Freeze_Request,
    VI_Preheat_Request := GVL_STATE.G_Preheat_Request,
    VI_DHW_Heating_Pump_Feedback := GVL_STATE.G_DHW_Heating_Pump,
    VI_Policy_Target_Adjustment := GVL_HEATING_POLICY.G_Policy_Target_Adjustment,
    VI_Boiler_Modulation_Raw := GVL_IO.AI_Boiler_Modulation
);

fbThermalAllocation(
    VI_Zone_Configs := GVL_CONFIG.G_HMI_FloorHeating_Configs,
    VI_Circuit_To_Zone := GVL_CONFIG.G_Heating_Circuit_To_Zone,
    VI_Manifold_Base_Priority := GVL_CONFIG.G_Manifold_Priority,
    VI_Zone_Priority_Bias := GVL_HEATING_POLICY.G_Zone_Priority_Bias,
    VI_Manifold_Pump_In_Service := GVL_CONFIG.G_Manifold_Pump_In_Service,
    VI_Max_Thermal_Budget := GVL_CONFIG.G_Max_Thermal_Budget
);

fbHeatingOrchestration(
    VI_System_Time_MS := GVL_TIME_SERVICE.G_Now_MS,
    VI_Current_TOD := GVL_STATUS.G_Current_TOD,
    VI_Current_Day_Of_Week := TO_UINT(GVL_TIME_SERVICE.G_Day_Of_Week),
    VI_IsActivePLC := GVL_STATUS.G_Is_Active_PLC,
    VI_Outdoor_Temp := L_Outdoor_Temp,
    VI_Floor_Temps := L_Floor_Temps,
    VI_Room_Temps := L_Room_Temps,
    VI_Config := GVL_CONFIG.G_Heating_Config,
    VI_Zone_Configs := GVL_CONFIG.G_HMI_FloorHeating_Configs,
    VI_Tariff := GVL_CONFIG.G_HMI_Tariff_Settings,
    VI_Time_Of_Day_MS := GVL_TIME_SERVICE.G_Time_Of_Day_MS,
    VI_Manifold_Pressures := L_Manifold_Pressures,
    VI_Manifold_Currents := GVL_STATE.G_Manifold_Currents,
    VI_Manifold_Temps_Supply := GVL_STATE.G_Manifold_T_Supply,
    VI_Manifold_Temps_Return := GVL_STATE.G_Manifold_T_Return,
    VI_Boiler_Flame_Status := GVL_STATE.G_Boiler_Flame,
    VI_Boiler_Error_Status := GVL_STATE.G_Boiler_Error,
    VI_Boiler_OT_Online := GVL_STATE.G_Boiler_OT_Online,
    VI_Boiler_Modulation := fbLocalContext.VO_Boiler_Modulation_REAL,
    VI_Rule_Actions := GVL_STATE.G_Rule_Actions,
    VI_IO_Modules_Online := GVL_STATUS.G_IO_Modules_Online,
    VI_DHW_Heating_Demand := fbLocalContext.VO_Heating_DHW_Demand,
    VI_DHW_Target_Temp := GVL_CONFIG.G_DHW_Config.Target_Temp,
    VI_DHW_Temp := GVL_STATE.G_DHW_Temp,
    VI_DHW_Pressure := GVL_STATE.G_DHW_Pressure,
    VI_DHW_Config := GVL_CONFIG.G_DHW_Config,
    VI_Reset_Errors := GVL_INTENT_USER.I_Reset_Errors,
    VI_System_Mode := GVL_STATE.G_System_Mode,
    VI_Emergency_Stop := fbLocalContext.VO_Heating_Emergency_Stop,
    VI_Gas_Safety_Stop := fbLocalContext.VO_Heating_Gas_Safety_Stop,
    VI_Manifold_End_Switches := GVL_STATE.G_Manifold_End_Switches,
    VI_Valve_Test_Config := GVL_CONFIG.G_Valve_Test_Config,
    VI_Block_Heating := GVL_COMMAND_SHADOW.G_Heating_Block,
    VI_Manifold_Enabled := fbThermalAllocation.VO_Manifold_Enabled,
    VIO_Manifold_Valves := L_Manifold_Valves,
    VIO_Manifold_Pumps := L_Manifold_Pumps,
    VIO_Zone_Valves := L_Zone_Valves,
    VIO_Boiler_OT_Enable := L_Boiler_OT_Enable,
    VIO_Boiler_OT_Setpoint := L_Boiler_OT_Setpoint,
    VIO_Backup_Circulation_Pump := L_Backup_Circulation_Pump,
    VIO_Electric_Heater_Enable := L_Electric_Heater_Enable,
    VIO_Freeze_Risk_Status := L_Freeze_Risk_Status,
    VIO_Manifold_Status := L_Manifold_Status,
    VIO_Boiler_Status := L_Boiler_Status,
    VIO_DHW_Heating_Pump := L_DHW_Heating_Pump,
    VIO_DHW_Circ_Pump := L_DHW_Circ_Pump,
    VIO_DHW_Status := L_DHW_Status
);

fbHeatingDiagnostics(VI_System_Time_MS := GVL_TIME_SERVICE.G_Now_MS);
fbHeatingMaintenanceGating();
fbHeatingFreezeHardware();

fbHeatingRootCauseDiagnostics(
    VI_Zone_Valves := L_Zone_Valves
);

GVL_STATE.G_DHW_Heating_Pump := L_DHW_Heating_Pump;

fbOutputProjection(
    VI_Zone_Valves := L_Zone_Valves,
    VI_Manifold_Pumps := L_Manifold_Pumps,
    VI_Manifold_Valves := L_Manifold_Valves,
    VI_DHW_Heating_Pump := L_DHW_Heating_Pump,
    VI_DHW_Circ_Pump := L_DHW_Circ_Pump,
    VI_Backup_Circulation_Pump := L_Backup_Circulation_Pump,
    VI_Electric_Heater_Enable := L_Electric_Heater_Enable
);

// >>> BULK_SYNC_ANCHOR: PRG_Heating <<<
