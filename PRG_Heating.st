PROGRAM PRG_Heating

VAR
    fbLocalContext : FB_Heating_Local_Context;
    fbThermalAllocation : FB_Heating_Thermal_Allocation;
    fbHeatingOrchestration : FB_Heating_Orchestration;
    fbHeatingDiagnostics : FB_Heating_Diagnostics;
    fbHeatingMaintenanceGating : FB_Heating_Maintenance_Gating;
    fbHeatingFreezeHardware : FB_Heating_Freeze_Hardware;
    fbHeatingAdapterCopyOut : FB_Heating_Adapter_CopyOut;
    fbHeatingRootCauseDiagnostics : FB_Heating_RootCause_Diagnostics;

    L_Zone_Valves : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF BOOL;
END_VAR

// === LOCAL CONTEXT ===
fbLocalContext(
    VI_System_Time_MS := GVL_TIME_SERVICE.G_Now_MS,
    VI_Safety_Emergency_Stop := GVL_STATE.G_Safety_Emergency_Stop,
    VI_Safety_Gas_Latched := GVL_STATE.G_Safety_Gas_Latched,
    VI_DHW_Block := GVL_COMMAND_SHADOW.G_Heating_DHW_Block,
    VI_Freeze_Request := GVL_STATE.G_Freeze_Request,
    VI_Preheat_Request := GVL_STATE.G_Preheat_Request,
    VI_DHW_Heating_Pump_Feedback := GVL_STATE.G_DHW_Heating_Pump,
    VI_Policy_Target_Adjustment := GVL_HEATING_POLICY.G_Policy_Target_Adjustment,
    VI_Boiler_Modulation_Raw := GVL_IO.AI_Boiler_Modulation
);

GVL_STATE.G_Target_Temperature := fbLocalContext.VO_Target_Temperature;

// === THERMAL ALLOCATION ===
fbThermalAllocation(
    VI_Zone_Configs := GVL_CONFIG.G_HMI_FloorHeating_Configs,
    VI_Circuit_To_Zone := GVL_CONFIG.G_Heating_Circuit_To_Zone,
    VI_Manifold_Base_Priority := GVL_CONFIG.G_Manifold_Priority,
    VI_Zone_Priority_Bias := GVL_HEATING_POLICY.G_Zone_Priority_Bias,
    VI_Guest_Preheat_Enabled := GVL_HEATING_POLICY_CONFIG.G_Guest_Preheat_Enabled,
    VI_Zone_Guest_Preheat_Request := GVL_HEATING_POLICY.G_Zone_Guest_Preheat_Request,
    VI_Guest_Preheat_Priority_Boost := GVL_HEATING_POLICY_CONFIG.G_Guest_Preheat_Priority_Boost,
    VI_Zone_Target_Adjustment := GVL_HEATING_POLICY.G_Zone_Target_Adjustment,
    VI_Zone_Self_Level := GVL_HEATING_POLICY.G_Zone_Self_Level,
    VI_Policy_Priority_Multiplier := GVL_HEATING_POLICY.G_Policy_Priority_Multiplier,
    VI_Manifold_Pump_In_Service := GVL_CONFIG.G_Manifold_Pump_In_Service,
    VI_Manifold_Pressure_Fault := GVL_STATUS.G_Diagnostics.Manifold_Pressure_Fault,
    VI_Manifold_Current_Fault := GVL_STATUS.G_Diagnostics.Manifold_Current_Fault,
    VI_Manifold_Thermal_Weight := GVL_CONFIG.G_Manifold_Thermal_Weight,
    VI_Max_Thermal_Budget := GVL_CONFIG.G_Max_Thermal_Budget
);

// === ORCHESTRATION ===
fbHeatingOrchestration(
    VI_System_Time_MS := GVL_TIME_SERVICE.G_Now_MS,
    VI_Current_TOD := GVL_STATUS.G_Current_TOD,
    VI_Current_Day_Of_Week := TO_UINT(GVL_TIME_SERVICE.G_Day_Of_Week),
    VI_IsActivePLC := GVL_STATUS.G_Is_Active_PLC,
    VI_Outdoor_Temp := GVL_STATE.G_Outdoor_Temp,
    VI_Floor_Temps := GVL_STATE.G_Floor_Temps,
    VI_Room_Temps := GVL_STATE.G_Room_Temps,
    VI_Config := GVL_CONFIG.G_Heating_Config,
    VI_Zone_Configs := GVL_CONFIG.G_HMI_FloorHeating_Configs,
    VI_Tariff := GVL_CONFIG.G_HMI_Tariff_Settings,
    VI_Time_Of_Day_MS := GVL_TIME_SERVICE.G_Time_Of_Day_MS,
    VI_Manifold_Pressures := GVL_STATE.G_Manifold_Pressures,
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
    VIO_Manifold_Valves := GVL_STATE.G_Manifold_Valves,
    VIO_Manifold_Pumps := GVL_STATE.G_Manifold_Pumps,
    VIO_Zone_Valves := L_Zone_Valves,
    VIO_Boiler_OT_Enable := GVL_STATE.G_Boiler_OT_Enable,
    VIO_Boiler_OT_Setpoint := GVL_STATE.G_Boiler_OT_Setpoint,
    VIO_Backup_Circulation_Pump := GVL_STATE.G_Backup_Circulation_Pump,
    VIO_Electric_Heater_Enable := GVL_STATE.G_Electric_Heater_Enable,
    VIO_Freeze_Risk_Status := GVL_STATE.G_Safety_Freeze_Risk,
    VIO_Manifold_Status := GVL_STATUS.G_Manifold_Status,
    VIO_Boiler_Status := GVL_STATUS.G_Boiler_Status,
    VIO_DHW_Heating_Pump := GVL_STATE.G_DHW_Heating_Pump,
    VIO_DHW_Circ_Pump := GVL_STATE.G_DHW_Circ_Pump,
    VIO_DHW_Status := GVL_STATUS.G_DHW_Status
);

// === POST ===
fbHeatingDiagnostics(VI_System_Time_MS := GVL_TIME_SERVICE.G_Now_MS);
fbHeatingMaintenanceGating();
fbHeatingFreezeHardware();

fbHeatingAdapterCopyOut(
    VI_Zone_Valves := L_Zone_Valves,
    VIO_Zone_Valves_State := GVL_STATE.G_Zone_Valves
);

fbHeatingRootCauseDiagnostics(
    VI_Zone_Valves := L_Zone_Valves
);

// >>> BULK_SYNC_ANCHOR: PRG_Heating <<<
