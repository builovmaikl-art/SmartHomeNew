FUNCTION_BLOCK FB_Heating_Orchestration
VAR_INPUT
    VI_System_Time_MS : UDINT;
    VI_Current_TOD : TOD;
    VI_Current_Day_Of_Week : UINT;
    VI_IsActivePLC : BOOL;
    VI_Outdoor_Temp : REAL;
    VI_Floor_Temps : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF REAL;
    VI_Room_Temps : ARRAY[1..GVL_CONSTANTS.C_MAX_ZONES] OF REAL;
    VI_Config : ST_Heating_Config;
    VI_Zone_Configs : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF ST_FloorHeating_Circuit_Config;
    VI_Tariff : ST_Tariff_Config;
    VI_Time_Of_Day_MS : UDINT;
    VI_Manifold_Pressures : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL;
    VI_Manifold_Currents : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL;
    VI_Manifold_Temps_Supply : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL;
    VI_Manifold_Temps_Return : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL;
    VI_Boiler_Flame_Status : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF BOOL;
    VI_Boiler_Error_Status : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF BOOL;
    VI_Boiler_OT_Online : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF BOOL;
    VI_Boiler_Modulation : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF REAL;
    VI_Rule_Actions : ARRAY[1..GVL_CONSTANTS.C_MAX_RULES] OF ST_Rule_Action;
    VI_IO_Modules_Online : ARRAY[1..GVL_CONSTANTS.C_MAX_MODULES] OF BOOL;
    VI_DHW_Heating_Demand : BOOL;
    VI_DHW_Target_Temp : REAL;
    VI_DHW_Temp : REAL;
    VI_DHW_Pressure : REAL;
    VI_DHW_Config : ST_DHW_Config;
    VI_Reset_Errors : BOOL;
    VI_System_Mode : E_System_Operating_Mode;
    VI_Emergency_Stop : BOOL;
    VI_Gas_Safety_Stop : BOOL;
    VI_Manifold_End_Switches : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    VI_Valve_Test_Config : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF ST_Valve_Test_Config;
    VI_Block_Heating : BOOL;
    VI_Manifold_Enabled : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
END_VAR
VAR_IN_OUT
    VIO_Manifold_Valves : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL;
    VIO_Manifold_Pumps : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    VIO_Zone_Valves : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF BOOL;
    VIO_Boiler_OT_Enable : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF BOOL;
    VIO_Boiler_OT_Setpoint : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF REAL;
    VIO_Backup_Circulation_Pump : BOOL;
    VIO_Electric_Heater_Enable : BOOL;
    VIO_Freeze_Risk_Status : BOOL;
    VIO_Manifold_Status : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF ST_Manifold_Status;
    VIO_Boiler_Status : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF ST_Boiler_Status;
    VIO_DHW_Heating_Pump : BOOL;
    VIO_DHW_Circ_Pump : BOOL;
    VIO_DHW_Status : ST_DHW_Status;
END_VAR
VAR
    fbCore : FB_Heating_Execution_Core;
    fbOverride : FB_Heating_Override_Layer;
END_VAR

// Step 1: execution core
fbCore(
    VI_System_Time_MS := VI_System_Time_MS,
    VI_Current_TOD := VI_Current_TOD,
    VI_Current_Day_Of_Week := VI_Current_Day_Of_Week,
    VI_IsActivePLC := VI_IsActivePLC,
    VI_Outdoor_Temp := VI_Outdoor_Temp,
    VI_Floor_Temps := VI_Floor_Temps,
    VI_Room_Temps := VI_Room_Temps,
    VI_Config := VI_Config,
    VI_Zone_Configs := VI_Zone_Configs,
    VI_Tariff := VI_Tariff,
    VI_Time_Of_Day_MS := VI_Time_Of_Day_MS,
    VI_Manifold_Pressures := VI_Manifold_Pressures,
    VI_Manifold_Currents := VI_Manifold_Currents,
    VI_Manifold_Temps_Supply := VI_Manifold_Temps_Supply,
    VI_Manifold_Temps_Return := VI_Manifold_Temps_Return,
    VI_Boiler_Flame_Status := VI_Boiler_Flame_Status,
    VI_Boiler_Error_Status := VI_Boiler_Error_Status,
    VI_Boiler_OT_Online := VI_Boiler_OT_Online,
    VI_Boiler_Modulation := VI_Boiler_Modulation,
    VI_Rule_Actions := VI_Rule_Actions,
    VI_IO_Modules_Online := VI_IO_Modules_Online,
    VI_DHW_Heating_Demand := VI_DHW_Heating_Demand,
    VI_DHW_Target_Temp := VI_DHW_Target_Temp,
    VI_DHW_Temp := VI_DHW_Temp,
    VI_DHW_Pressure := VI_DHW_Pressure,
    VI_DHW_Config := VI_DHW_Config,
    VI_Reset_Errors := VI_Reset_Errors,
    VI_System_Mode := VI_System_Mode,
    VI_Emergency_Stop := VI_Emergency_Stop,
    VI_Gas_Safety_Stop := VI_Gas_Safety_Stop,
    VI_Manifold_End_Switches := VI_Manifold_End_Switches,
    VI_Valve_Test_Config := VI_Valve_Test_Config,
    VIO_Manifold_Valves := VIO_Manifold_Valves,
    VIO_Manifold_Pumps := VIO_Manifold_Pumps,
    VIO_Zone_Valves := VIO_Zone_Valves,
    VIO_Boiler_OT_Enable := VIO_Boiler_OT_Enable,
    VIO_Boiler_OT_Setpoint := VIO_Boiler_OT_Setpoint,
    VIO_Backup_Circulation_Pump := VIO_Backup_Circulation_Pump,
    VIO_Electric_Heater_Enable := VIO_Electric_Heater_Enable,
    VIO_Freeze_Risk_Status := VIO_Freeze_Risk_Status,
    VIO_Manifold_Status := VIO_Manifold_Status,
    VIO_Boiler_Status := VIO_Boiler_Status,
    VIO_DHW_Heating_Pump := VIO_DHW_Heating_Pump,
    VIO_DHW_Circ_Pump := VIO_DHW_Circ_Pump,
    VIO_DHW_Status := VIO_DHW_Status
);

// Step 2: override layer
fbOverride(
    VI_Block_Heating := VI_Block_Heating,
    VI_Manifold_Enabled := VI_Manifold_Enabled,
    VI_Zone_Configs := VI_Zone_Configs,
    VIO_Manifold_Valves := VIO_Manifold_Valves,
    VIO_Manifold_Pumps := VIO_Manifold_Pumps,
    VIO_Zone_Valves := VIO_Zone_Valves
);

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Orchestration <<<
