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
    L_Outdoor_Temp : REAL;
    L_Room_Temps : ARRAY[1..GVL_CONSTANTS.C_MAX_ZONES] OF REAL;
    L_Floor_Temps : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF REAL;
    L_Manifold_Pressures : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL;
    L_Zone_Configs : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF ST_FloorHeating_Circuit_Config;
    L_Circuit_To_Zone : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF INT;
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

IF (GVL_STATE.G_Outdoor_Temp > -50.0) AND (GVL_STATE.G_Outdoor_Temp < 60.0) THEN
    L_Outdoor_Temp := LIMIT(-50.0, GVL_STATE.G_Outdoor_Temp, 60.0);
ELSE
    L_Outdoor_Temp := 0.0;
END_IF;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_ZONES DO
    IF (GVL_STATE.G_Room_Temps[L_i] > -50.0) AND (GVL_STATE.G_Room_Temps[L_i] < 100.0) THEN
        L_Room_Temps[L_i] := GVL_STATE.G_Room_Temps[L_i];
    ELSE
        L_Room_Temps[L_i] := 20.0;
    END_IF;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
    IF (GVL_STATE.G_Floor_Temps[L_i] > -50.0) AND (GVL_STATE.G_Floor_Temps[L_i] < 100.0) THEN
        L_Floor_Temps[L_i] := GVL_STATE.G_Floor_Temps[L_i];
    ELSE
        L_Floor_Temps[L_i] := 20.0;
    END_IF;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    IF (GVL_STATE.G_Manifold_Pressures[L_i] > 0.1) THEN
        L_Manifold_Pressures[L_i] := GVL_STATE.G_Manifold_Pressures[L_i];
    ELSE
        L_Manifold_Pressures[L_i] := 0.0;
    END_IF;
END_FOR;

// rest unchanged
// >>> BULK_SYNC_ANCHOR: PRG_Heating <<<
