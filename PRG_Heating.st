PROGRAM PRG_Heating
VAR
    fbHeatingManager : FB_Heating_System_Manager;
    fbDHWManager : FB_DHW_Manager;
    fbOutputProjection : FB_Heating_Output_Projection;
    fbRootCauseDiagnostics : FB_Heating_RootCause_Diagnostics;

    L_i : INT;
    L_Current_Hour : UINT;
    L_Boiler_Modulation_REAL : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF REAL;

    L_Heating_Emergency_Stop : BOOL;
    L_Heating_Gas_Safety_Stop : BOOL;

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

// ======================================================
// INPUT ADAPTERS
// ======================================================
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BOILERS DO
    L_Boiler_Modulation_REAL[L_i] := TO_REAL(GVL_IO.AI_Boiler_Modulation[L_i]);
END_FOR;

L_Current_Hour := TO_UINT(GVL_TIME_SERVICE.G_Time_Of_Day_MS / 3600000);

L_Heating_Emergency_Stop := GVL_COMMAND_SHADOW.G_Heating_Emergency_Stop;
L_Heating_Gas_Safety_Stop := GVL_COMMAND_SHADOW.G_Heating_Gas_Safety_Stop OR GVL_STATE.G_Safety_Gas_Latched;

// ======================================================
// DHW EXECUTION
// ======================================================
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
    VI_Emergency_Stop := L_Heating_Emergency_Stop,
    VI_System_Mode := GVL_STATE.G_System_Mode,
    VO_Status => L_DHW_Status,
    VO_Heating_Pump => L_DHW_Heating_Pump,
    VO_Circ_Pump => L_DHW_Circ_Pump
);

// Gas safety disables DHW heating demand, but keeps DHW circulation policy intact.
// The electric backup heater is reserved for freeze protection of the heating system, not for DHW.
IF L_Heating_Gas_Safety_Stop THEN
    L_DHW_Heating_Pump := FALSE;
    L_DHW_Status.Heating_Pump_On := FALSE;
END_IF;

// ======================================================
// HEATING EXECUTION CORE
// ======================================================
fbHeatingManager(
    VI_System_Mode := GVL_STATE.G_System_Mode,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_IsActivePLC := GVL_STATUS.G_Is_Active_PLC,
    VI_Outdoor_Temp := GVL_STATE.G_Outdoor_Temp,
    VI_Config := GVL_CONFIG.G_Heating_Config,
    VI_Tariff := GVL_CONFIG.G_HMI_Tariff_Settings,
    VI_Current_Hour := L_Current_Hour,
    VI_DHW_Heating_Demand := L_DHW_Heating_Pump,
    VI_DHW_Target_Temp := GVL_CONFIG.G_DHW_Config.Target_Temp,
    VI_Emergency_Stop := L_Heating_Emergency_Stop,
    VI_Gas_Safety_Stop := L_Heating_Gas_Safety_Stop,
    VI_Boiler_Error_Status := GVL_STATE.G_Boiler_Error,
    VI_Boiler_OT_Online := GVL_STATE.G_Boiler_OT_Online,
    VI_Boiler_Modulation := L_Boiler_Modulation_REAL,
    VI_Floor_Temps := GVL_STATE.G_Floor_Temps,
    VI_Room_Temps := GVL_STATE.G_Room_Temps,
    VI_Manifold_Pressures := GVL_STATE.G_Manifold_Pressures,
    VI_Manifold_Currents := GVL_STATE.G_Manifold_Currents,
    VI_Manifold_Temps_Supply := GVL_STATE.G_Manifold_T_Supply,
    VI_Manifold_Temps_Return := GVL_STATE.G_Manifold_T_Return,
    VI_Boiler_Flame_Status := GVL_STATE.G_Boiler_Flame,
    VI_Zone_Configs := GVL_CONFIG.G_HMI_FloorHeating_Configs,
    VI_Rule_Actions := GVL_STATE.G_Rule_Actions,
    VI_IO_Modules_Online := GVL_STATUS.G_IO_Modules_Online,
    VI_Manifold_End_Switches := GVL_STATE.G_Manifold_End_Switches,
    VI_Valve_Test_Config := GVL_CONFIG.G_Valve_Test_Config,
    VO_Manifold_Valves => L_Manifold_Valves,
    VO_Manifold_Pumps => L_Manifold_Pumps,
    VO_Zone_Valves => L_Zone_Valves,
    VO_Boiler_OT_Enable => L_Boiler_OT_Enable,
    VO_Boiler_OT_Setpoint => L_Boiler_OT_Setpoint,
    VO_Backup_Circulation_Pump => L_Backup_Circulation_Pump,
    VO_Electric_Heater_Enable => L_Electric_Heater_Enable,
    VO_Freeze_Risk_Status => L_Freeze_Risk_Status,
    VO_Status => L_Manifold_Status,
    VO_Boiler_Status => L_Boiler_Status
);

// ======================================================
// MAINTENANCE / SERVICE GATING
// ======================================================
GVL_STATUS.G_Diagnostics.Backup_Pump_Out_Of_Service := NOT GVL_CONFIG.G_Backup_Circulation_Pump_In_Service;
GVL_STATUS.G_Diagnostics.Electric_Heater_Out_Of_Service := NOT GVL_CONFIG.G_Electric_Heater_In_Service;

IF NOT GVL_CONFIG.G_Backup_Circulation_Pump_In_Service THEN
    L_Backup_Circulation_Pump := FALSE;
END_IF;

IF NOT GVL_CONFIG.G_Electric_Heater_In_Service THEN
    L_Electric_Heater_Enable := FALSE;
END_IF;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    GVL_STATUS.G_Diagnostics.Manifold_Pump_Out_Of_Service[L_i] := NOT GVL_CONFIG.G_Manifold_Pump_In_Service[L_i];
    IF NOT GVL_CONFIG.G_Manifold_Pump_In_Service[L_i] THEN
        L_Manifold_Pumps[L_i] := FALSE;
    END_IF;
END_FOR;

GVL_STATUS.G_Diagnostics.DHW_Heating_Pump_Out_Of_Service := NOT GVL_CONFIG.G_DHW_Heating_Pump_In_Service;
IF NOT GVL_CONFIG.G_DHW_Heating_Pump_In_Service THEN
    L_DHW_Heating_Pump := FALSE;
    L_DHW_Status.Heating_Pump_On := FALSE;
END_IF;

GVL_STATUS.G_Diagnostics.DHW_Circ_Pump_Out_Of_Service := NOT GVL_CONFIG.G_DHW_Circ_Pump_In_Service;
IF NOT GVL_CONFIG.G_DHW_Circ_Pump_In_Service THEN
    L_DHW_Circ_Pump := FALSE;
    L_DHW_Status.Circ_Pump_On := FALSE;
END_IF;

GVL_STATE.G_Freeze_Hardware_Degraded := GVL_STATUS.G_Diagnostics.Backup_Pump_Fault OR GVL_STATUS.G_Diagnostics.Electric_Heater_Fault;
GVL_STATE.G_Freeze_Hardware_Failed := GVL_STATUS.G_Diagnostics.Backup_Pump_Fault AND GVL_STATUS.G_Diagnostics.Electric_Heater_Fault;

IF GVL_STATE.G_Freeze_Hardware_Failed THEN
    L_Backup_Circulation_Pump := FALSE;
    L_Electric_Heater_Enable := FALSE;
    L_Freeze_Risk_Status := TRUE;
END_IF;

// ======================================================
// STATE / STATUS COPY OUT
// ======================================================
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
    GVL_STATE.G_Zone_Valves[L_i] := L_Zone_Valves[L_i];
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    GVL_STATE.G_Manifold_Pumps[L_i] := L_Manifold_Pumps[L_i];
    GVL_STATE.G_Manifold_Valves[L_i] := L_Manifold_Valves[L_i];
    GVL_STATUS.G_Manifold_Status[L_i] := L_Manifold_Status[L_i];
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BOILERS DO
    GVL_STATE.G_Boiler_OT_Enable[L_i] := L_Boiler_OT_Enable[L_i];
    GVL_STATE.G_Boiler_OT_Setpoint[L_i] := L_Boiler_OT_Setpoint[L_i];
    GVL_STATUS.G_Boiler_Status[L_i] := L_Boiler_Status[L_i];
END_FOR;

GVL_STATE.G_Backup_Circulation_Pump := L_Backup_Circulation_Pump;
GVL_STATE.G_Electric_Heater_Enable := L_Electric_Heater_Enable;
GVL_STATE.G_Safety_Freeze_Risk := L_Freeze_Risk_Status;
GVL_STATE.G_DHW_Heating_Pump := L_DHW_Heating_Pump;
GVL_STATE.G_DHW_Circ_Pump := L_DHW_Circ_Pump;
GVL_STATUS.G_DHW_Status := L_DHW_Status;

// ======================================================
// READ-ONLY ROOT CAUSE DIAGNOSTICS
// ======================================================
fbRootCauseDiagnostics(
    VI_Enable := TRUE
);

// ======================================================
// DOMAIN OUTPUT PROJECTION
// ======================================================
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
END_PROGRAM
