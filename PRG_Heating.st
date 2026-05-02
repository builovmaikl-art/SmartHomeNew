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
    L_Zone_Index : INT;
    L_Manifold_Index : INT;
    L_Sensor_Index : INT;
    L_Config_Mapping_Error : BOOL;

    // Normalized inputs and configs
    L_Outdoor_Temp : REAL;
    L_Room_Temps : ARRAY[1..GVL_CONSTANTS.C_MAX_ZONES] OF REAL;
    L_Floor_Temps : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF REAL;
    L_Manifold_Pressures : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL;
    L_Zone_Configs : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF ST_FloorHeating_Circuit_Config;
    L_Circuit_To_Zone : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF INT;

    // Local actuator buffers (no direct writes to GVL_STATE)
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

// Normalize inputs
IF IS_REAL_VALID(GVL_STATE.G_Outdoor_Temp) THEN
    L_Outdoor_Temp := LIMIT(-50.0, GVL_STATE.G_Outdoor_Temp, 60.0);
ELSE
    L_Outdoor_Temp := 0.0;
END_IF;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_ZONES DO
    IF IS_REAL_VALID(GVL_STATE.G_Room_Temps[L_i]) AND
       (GVL_STATE.G_Room_Temps[L_i] > -50.0) AND
       (GVL_STATE.G_Room_Temps[L_i] < 100.0) THEN
        L_Room_Temps[L_i] := GVL_STATE.G_Room_Temps[L_i];
    ELSE
        L_Room_Temps[L_i] := 20.0;
    END_IF;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
    IF IS_REAL_VALID(GVL_STATE.G_Floor_Temps[L_i]) AND
       (GVL_STATE.G_Floor_Temps[L_i] > -50.0) AND
       (GVL_STATE.G_Floor_Temps[L_i] < 100.0) THEN
        L_Floor_Temps[L_i] := GVL_STATE.G_Floor_Temps[L_i];
    ELSE
        L_Floor_Temps[L_i] := 20.0;
    END_IF;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    IF IS_REAL_VALID(GVL_STATE.G_Manifold_Pressures[L_i]) AND
       (GVL_STATE.G_Manifold_Pressures[L_i] > 0.1) THEN
        L_Manifold_Pressures[L_i] := GVL_STATE.G_Manifold_Pressures[L_i];
    ELSE
        L_Manifold_Pressures[L_i] := 0.0;
    END_IF;
END_FOR;

// Validate mapping
L_Config_Mapping_Error := FALSE;
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
    L_Zone_Configs[L_i] := GVL_CONFIG.G_HMI_FloorHeating_Configs[L_i];

    L_Zone_Index := GVL_CONFIG.G_Heating_Circuit_To_Zone[L_i];
    L_Manifold_Index := BYTE_TO_INT(L_Zone_Configs[L_i].manifold_id);
    L_Sensor_Index := BYTE_TO_INT(L_Zone_Configs[L_i].sensor_id);

    IF (L_Zone_Index < 1) OR (L_Zone_Index > GVL_CONSTANTS.C_MAX_ZONES) THEN
        L_Config_Mapping_Error := TRUE;
        L_Circuit_To_Zone[L_i] := 1;
    ELSE
        L_Circuit_To_Zone[L_i] := L_Zone_Index;
    END_IF;

    IF (L_Manifold_Index < 1) OR (L_Manifold_Index > GVL_CONSTANTS.C_MAX_MANIFOLDS) THEN
        L_Config_Mapping_Error := TRUE;
    END_IF;

    IF (L_Sensor_Index < 1) OR (L_Sensor_Index > GVL_CONSTANTS.C_MAX_ZONES) THEN
        L_Config_Mapping_Error := TRUE;
    END_IF;
END_FOR;

// FAIL-FAST
IF L_Config_Mapping_Error THEN
    GVL_STATUS.G_Diagnostics.Subsystem_Degraded := TRUE;
    GVL_COMMAND_SHADOW.G_Heating_Block := TRUE;
    GVL_COMMAND_SHADOW.G_Boiler_Stop := TRUE;
    RETURN;
END_IF;

// Safe init
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

// Core pipeline (unchanged)
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
    VI_Zone_Configs := L_Zone_Configs,
    VI_Circuit_To_Zone := L_Circuit_To_Zone,
    VI_Manifold_Base_Priority := GVL_CONFIG.G_Manifold_Priority,
    VI_Zone_Priority_Bias := GVL_HEATING_POLICY.G_Zone_Priority_Bias,
    VI_Manifold_Pump_In_Service := GVL_CONFIG.G_Manifold_Pump_In_Service,
    VI_Max_Thermal_Budget := GVL_CONFIG.G_Max_Thermal_Budget
);

fbHeatingOrchestration(
    VI_System_Time_MS := GVL_TIME_SERVICE.G_Now_MS,
    VI_IsActivePLC := GVL_STATUS.G_Is_Active_PLC,
    VI_Outdoor_Temp := L_Outdoor_Temp,
    VI_Floor_Temps := L_Floor_Temps,
    VI_Room_Temps := L_Room_Temps,
    VI_Manifold_Pressures := L_Manifold_Pressures,
    VIO_Zone_Valves := L_Zone_Valves,
    VIO_Manifold_Pumps := L_Manifold_Pumps
);

fbOutputProjection(
    VI_Zone_Valves := L_Zone_Valves
);

// >>> BULK_SYNC_ANCHOR: PRG_Heating <<<
