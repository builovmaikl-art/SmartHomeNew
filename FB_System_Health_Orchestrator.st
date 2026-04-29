// ==============================================================================
// System health orchestrator helper
//
// Internal helper for PRG_System.
// Owns safety latch update, watchdog, system health aggregation,
// system mode calculation, HMI/fault publication, diagnostic exports,
// and human-readable mode/cause text projection.
// ==============================================================================
FUNCTION_BLOCK FB_System_Health_Orchestrator
VAR
    fbSafety : FB_Safety_Manager;
    fbWatchdog : FB_Watchdog;
    fbSystemHealth : FB_System_Health;
    fbStateManager : FB_State_Manager;
    fbHMIInterface : FB_HMI_Interface;
    fbFaultLogger : FB_Fault_Logger;
END_VAR

fbSafety(
    VI_Gas_Alarm := GVL_STATE.G_Safety_Gas_Alarm,
    VI_Leak_Alarm := GVL_STATE.G_Safety_Leak_Alarm,
    VI_Smoke_Alarm := GVL_STATE.G_Safety_Smoke_Alarm,
    VI_Reset := GVL_COMMAND.G_Reset_Errors,
    VO_Gas_Latched => GVL_STATE.G_Safety_Gas_Latched,
    VO_Leak_Latched => GVL_STATE.G_Safety_Leak_Latched,
    VO_Smoke_Latched => GVL_STATE.G_Safety_Smoke_Latched,
    VO_Emergency_Stop => GVL_STATE.G_Safety_Emergency_Stop
);

GVL_STATE.G_Freeze_Hardware_Degraded := GVL_STATUS.G_Diagnostics.Backup_Pump_Fault OR GVL_STATUS.G_Diagnostics.Electric_Heater_Fault;
GVL_STATE.G_Freeze_Hardware_Failed := GVL_STATUS.G_Diagnostics.Backup_Pump_Fault AND GVL_STATUS.G_Diagnostics.Electric_Heater_Fault;

fbWatchdog(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

fbSystemHealth(
    VI_Smoke_Detected := GVL_HEALTH_BRIDGE.G_Smoke_Detected OR GVL_STATE.G_Safety_Smoke_Latched,
    VI_Gas_Detected := GVL_HEALTH_BRIDGE.G_Gas_Detected OR GVL_STATE.G_Safety_Gas_Latched,
    VI_CO_Warning_Level := GVL_HEALTH_BRIDGE.G_CO_Warning_Level,
    VI_CO_Alarm_Level := GVL_HEALTH_BRIDGE.G_CO_Alarm_Level,
    VI_Leak_Detected := GVL_HEALTH_BRIDGE.G_Leak_Detected OR GVL_STATE.G_Safety_Leak_Latched,
    VI_Sensor_Fault := GVL_STATE.G_Heating_Sensor_Fault OR GVL_STATE.G_DHW_Sensor_Fault OR GVL_STATUS.G_Diagnostics.Manifold_Pressure_Fault_Active OR GVL_STATUS.G_Diagnostics.Manifold_Current_Fault_Active OR GVL_STATUS.G_Diagnostics.Manifold_Return_Temp_Fault_Active,
    VI_IO_Offline := GVL_STATE.G_Heating_IO_Fault OR GVL_STATE.G_DHW_IO_Fault OR GVL_STATE.G_Ventilation_IO_Fault OR GVL_STATE.G_Lighting_IO_Fault,
    VI_Comm_Fault := GVL_STATE.G_Access_Comm_Fault,
    VI_Watchdog_Fault := fbWatchdog.VO_Watchdog_Fault,
    VI_Subsystem_Fault := GVL_STATE.G_Heating_Subsystem_Degraded OR GVL_STATE.G_DHW_Subsystem_Degraded OR GVL_STATE.G_Ventilation_Subsystem_Degraded OR GVL_STATUS.G_Diagnostics.Manifold_Pressure_Fault_Active OR GVL_STATUS.G_Diagnostics.Manifold_Current_Fault_Active OR GVL_STATUS.G_Diagnostics.Manifold_Return_Temp_Fault_Active
);

fbStateManager(
    VI_System_Severity := fbSystemHealth.VO_System_Severity,
    VI_Root_Cause := fbSystemHealth.VO_Root_Cause,
    VI_Freeze_Risk := GVL_STATE.G_Safety_Freeze_Risk
);

fbHMIInterface(
    VI_Severity := fbSystemHealth.VO_System_Severity,
    VI_RootCause := fbSystemHealth.VO_Root_Cause,
    VI_Status_Msg := fbStateManager.VO_Status_Msg
);

fbFaultLogger(
    VI_Severity := fbSystemHealth.VO_System_Severity,
    VI_RootCause := fbSystemHealth.VO_Root_Cause,
    VI_Time_MS := GVL_STATUS.G_System_Time_MS
);

GVL_STATUS.G_System_Mode_Msg := fbStateManager.VO_Status_Msg;

GVL_STATUS.G_Diagnostics.Sensor_Fault :=
    GVL_STATE.G_Heating_Sensor_Fault OR
    GVL_STATE.G_DHW_Sensor_Fault OR
    GVL_STATUS.G_Diagnostics.Manifold_Pressure_Fault_Active OR
    GVL_STATUS.G_Diagnostics.Manifold_Current_Fault_Active OR
    GVL_STATUS.G_Diagnostics.Manifold_Return_Temp_Fault_Active;

GVL_STATUS.G_Diagnostics.IO_Offline :=
    GVL_STATE.G_Heating_IO_Fault OR
    GVL_STATE.G_DHW_IO_Fault OR
    GVL_STATE.G_Ventilation_IO_Fault OR
    GVL_STATE.G_Lighting_IO_Fault;

GVL_STATUS.G_Diagnostics.Subsystem_Degraded :=
    GVL_STATE.G_Heating_Subsystem_Degraded OR
    GVL_STATE.G_DHW_Subsystem_Degraded OR
    GVL_STATE.G_Ventilation_Subsystem_Degraded OR
    GVL_STATUS.G_Diagnostics.Manifold_Pressure_Fault_Active OR
    GVL_STATUS.G_Diagnostics.Manifold_Current_Fault_Active OR
    GVL_STATUS.G_Diagnostics.Manifold_Return_Temp_Fault_Active;

GVL_GATEWAY.G_Gateway_HMI_Status_Message := fbHMIInterface.VO_HMI_Status_Text;
IF fbFaultLogger.VO_Last_Event_Text <> '' THEN
    GVL_HEALTH_BRIDGE.G_Last_Fault_Event_Text := fbFaultLogger.VO_Last_Event_Text;
END_IF;

GVL_STATE.G_System_Mode := fbStateManager.VO_System_Mode;

CASE GVL_STATE.G_System_Mode OF
    E_System_Operating_Mode.MODE_SAFE_STOP:
        GVL_STATE.G_System_Mode_Text := 'SAFE_STOP';

    E_System_Operating_Mode.MODE_FREEZE_PROTECTION:
        GVL_STATE.G_System_Mode_Text := 'FREEZE_PROTECTION';

    E_System_Operating_Mode.MODE_DEGRADED:
        GVL_STATE.G_System_Mode_Text := 'DEGRADED';

    ELSE
        GVL_STATE.G_System_Mode_Text := 'NORMAL';
END_CASE;

CASE fbSystemHealth.VO_Root_Cause OF
    E_System_Root_Cause.ROOT_FIRE:
        GVL_STATUS.G_System_Mode_Cause := 'Пожар/дым';
    E_System_Root_Cause.ROOT_GAS_LEAK:
        GVL_STATUS.G_System_Mode_Cause := 'Утечка газа';
    E_System_Root_Cause.ROOT_CO_CRITICAL:
        GVL_STATUS.G_System_Mode_Cause := 'Критический CO';
    E_System_Root_Cause.ROOT_CO_WARNING:
        GVL_STATUS.G_System_Mode_Cause := 'Повышенный CO';
    E_System_Root_Cause.ROOT_WATER_LEAK:
        GVL_STATUS.G_System_Mode_Cause := 'Протечка воды';
    E_System_Root_Cause.ROOT_WATCHDOG_FAULT:
        GVL_STATUS.G_System_Mode_Cause := 'Ошибка watchdog';
    E_System_Root_Cause.ROOT_IO_OFFLINE:
        GVL_STATUS.G_System_Mode_Cause := 'Недоступен модуль IO';
    E_System_Root_Cause.ROOT_COMM_FAULT:
        GVL_STATUS.G_System_Mode_Cause := 'Ошибка связи';
    E_System_Root_Cause.ROOT_SENSOR_FAULT:
        GVL_STATUS.G_System_Mode_Cause := 'Ошибка датчика';
    E_System_Root_Cause.ROOT_SUBSYSTEM_FAULT:
        GVL_STATUS.G_System_Mode_Cause := 'Ошибка подсистемы';
    ELSE
        GVL_STATUS.G_System_Mode_Cause := 'Аварийные режимы отсутствуют';
END_CASE;

GVL_STATUS.G_System_Mode_Msg := fbStateManager.VO_Status_Msg;

// >>> BULK_SYNC_ANCHOR: FB_System_Health_Orchestrator <<<
