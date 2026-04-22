PROGRAM PRG_Heating

VAR
    L_Last_Mode : INT := 0; // 0=normal,1=preheat,2=freeze
    L_Mode_Hold_Timer : FB_System_Timer;
END_VAR

VAR
    fbHeatingManager : FB_Heating_System_Manager;
    fbDHWManager : FB_DHW_Manager;
    L_i : INT;
    L_Zone_Valves_8 : ARRAY[1..8] OF BOOL;
    L_Boiler_Modulation_REAL : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF REAL;
    L_Heating_Emergency_Stop : BOOL;
    L_Heating_Gas_Safety_Stop : BOOL;
    L_Heating_DHW_Demand : BOOL;
END_VAR

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BOILERS DO
    L_Boiler_Modulation_REAL[L_i] := TO_REAL(GVL_IO.AI_Boiler_Modulation[L_i]);
END_FOR;

// === Heating Arbitration ===
L_Heating_Emergency_Stop := GVL_STATE.G_Safety_Emergency_Stop;
L_Heating_Gas_Safety_Stop := GVL_STATE.G_Safety_Gas_Latched;
L_Heating_DHW_Demand := fbDHWManager.VO_Heating_Pump;

// Priority 1: emergency stop
IF L_Heating_Emergency_Stop THEN
    L_Heating_Gas_Safety_Stop := FALSE;
    L_Heating_DHW_Demand := FALSE;
// Priority 2: gas safety stop
ELSIF L_Heating_Gas_Safety_Stop THEN
    L_Heating_DHW_Demand := FALSE;
ELSIF GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_DEGRADED THEN
    L_Heating_DHW_Demand := FALSE;
END_IF;

// --- CONSOLIDATED HEATING REQUEST / ARBITRATION / STABILIZATION ---
L_Mode_Hold_Timer(
    IN := TRUE,
    PT := T#30s,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

IF L_Mode_Hold_Timer.Q THEN
    IF GVL_STATE.G_Freeze_Request THEN
        L_Last_Mode := 2; // freeze
    ELSIF GVL_STATE.G_Preheat_Request THEN
        L_Last_Mode := 1; // preheat
    ELSE
        L_Last_Mode := 0; // normal
    END_IF;
END_IF;

CASE L_Last_Mode OF
    2:
        GVL_STATE.G_Target_Temperature := 5.0;
    1:
        GVL_STATE.G_Target_Temperature := 22.0;
    ELSE
        GVL_STATE.G_Target_Temperature := 20.0;
END_CASE;

// 9. Управление климатом (Отопление)
fbHeatingManager(
    VI_Preheat_Request := GVL_HEATING_REQUEST.G_Preheat_Request,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Current_TOD := GVL_STATUS.G_Current_TOD,
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
    VI_Boiler_Stop := FALSE, // legacy input disabled; safety flows via mode/latches
    VI_IO_Modules_Online := GVL_STATUS.G_IO_Modules_Online,
    VI_DHW_Heating_Demand := L_Heating_DHW_Demand,
    VI_DHW_Target_Temp := GVL_CONFIG.G_DHW_Config.Target_Temp,
    VI_Current_Scenario := GVL_STATUS.G_Current_Scenario,
    VI_System_Mode := GVL_STATE.G_System_Mode,
    VI_Emergency_Stop := L_Heating_Emergency_Stop,
    VI_Gas_Safety_Stop := L_Heating_Gas_Safety_Stop,
    VI_Scenario_Configs := GVL_CONFIG.G_HMI_Scenario_Configs,
    VI_Manifold_End_Switches := GVL_STATE.G_Manifold_End_Switches,
    VI_Valve_Test_Config := GVL_CONFIG.G_Valve_Test_Config,
    VO_Manifold_Valves => GVL_STATE.G_Manifold_Valves,
    VO_Manifold_Pumps => GVL_STATE.G_Manifold_Pumps,
    VO_Zone_Valves => L_Zone_Valves_8,
    VO_Boiler_OT_Enable => GVL_STATE.G_Boiler_OT_Enable,
    VO_Boiler_OT_Setpoint => GVL_STATE.G_Boiler_OT_Setpoint,
    VO_Backup_Circulation_Pump => GVL_STATE.G_Backup_Circulation_Pump,
    VO_Electric_Heater_Enable => GVL_STATE.G_Electric_Heater_Enable,
    VO_Freeze_Risk_Status => GVL_STATE.G_Safety_Freeze_Risk,
    VO_Status => GVL_STATUS.G_Manifold_Status,
    VO_Boiler_Status => GVL_STATUS.G_Boiler_Status
);

// 12. Управление ГВС
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

// Integrated freeze-hardware diagnostics and maintenance gating
GVL_STATUS.G_Diagnostics.Backup_Pump_Out_Of_Service := NOT GVL_CONFIG.G_Backup_Circulation_Pump_In_Service;
GVL_STATUS.G_Diagnostics.Electric_Heater_Out_Of_Service := NOT GVL_CONFIG.G_Electric_Heater_In_Service;
IF NOT GVL_CONFIG.G_Backup_Circulation_Pump_In_Service THEN
    GVL_STATE.G_Backup_Circulation_Pump := FALSE;
END_IF;
IF NOT GVL_CONFIG.G_Electric_Heater_In_Service THEN
    GVL_STATE.G_Electric_Heater_Enable := FALSE;
END_IF;

GVL_STATE.G_Freeze_Hardware_Degraded := GVL_STATUS.G_Diagnostics.Backup_Pump_Fault OR GVL_STATUS.G_Diagnostics.Electric_Heater_Fault;
GVL_STATE.G_Freeze_Hardware_Failed := GVL_STATUS.G_Diagnostics.Backup_Pump_Fault AND GVL_STATUS.G_Diagnostics.Electric_Heater_Fault;

IF GVL_STATE.G_Freeze_Hardware_Failed THEN
    GVL_STATE.G_Backup_Circulation_Pump := FALSE;
    GVL_STATE.G_Electric_Heater_Enable := FALSE;
    GVL_STATE.G_Safety_Freeze_Risk := TRUE;
END_IF;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    GVL_STATUS.G_Diagnostics.Manifold_Pump_Out_Of_Service[L_i] := NOT GVL_CONFIG.G_Manifold_Pump_In_Service[L_i];
    IF NOT GVL_CONFIG.G_Manifold_Pump_In_Service[L_i] THEN
        GVL_STATE.G_Manifold_Pumps[L_i] := FALSE;
    END_IF;
END_FOR;
GVL_STATUS.G_Diagnostics.DHW_Heating_Pump_Out_Of_Service := NOT GVL_CONFIG.G_DHW_Heating_Pump_In_Service;
IF NOT GVL_CONFIG.G_DHW_Heating_Pump_In_Service THEN
    GVL_STATE.G_DHW_Heating_Pump := FALSE;
END_IF;
GVL_STATUS.G_Diagnostics.DHW_Circ_Pump_Out_Of_Service := NOT GVL_CONFIG.G_DHW_Circ_Pump_In_Service;
IF NOT GVL_CONFIG.G_DHW_Circ_Pump_In_Service THEN
    GVL_STATE.G_DHW_Circ_Pump := FALSE;
END_IF;
// >>> BULK_SYNC_ANCHOR: PRG_Heating <<<


// HEATING ADAPTER COPY OUT
FOR L_i := 1 TO 8 DO
    GVL_STATE.G_Zone_Valves[L_i] := L_Zone_Valves_8[L_i];
END_FOR;






