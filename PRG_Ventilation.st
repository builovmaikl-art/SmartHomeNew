PROGRAM PRG_Ventilation
VAR
    fbVentilationManager : FB_Ventilation_System_Manager;
    L_i : INT;
    L_Supply_Fans_Byte : ARRAY[1..GVL_CONSTANTS.C_MAX_SUPPLY_FANS] OF BYTE;
    L_Exhaust_Fans_Byte : ARRAY[1..GVL_CONSTANTS.C_MAX_EXHAUST_FANS] OF BYTE;
    L_Wet_Zone_Active : ARRAY[1..GVL_CONSTANTS.C_MAX_WET_ZONES] OF BOOL;
    L_Vent_PV3_Boost_Req : BOOL;
    L_Supply_100_Req : BOOL;
    L_Exhaust_100_Req : BOOL;
    L_Supply_80_Req : BOOL;
    L_Vent_Stop_Req : BOOL;
END_VAR

// Wet-zone adapter
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_WET_ZONES DO
    L_Wet_Zone_Active[L_i] := FALSE;
END_FOR;
IF GVL_STATUS.G_Wet_Zone_Light_Active THEN
    L_Wet_Zone_Active[1] := TRUE;
END_IF;

// === Ventilation Arbitration ===

// default: pass-through from shadow arbitration
L_Vent_PV3_Boost_Req := GVL_COMMAND_SHADOW.G_Vent_PV3_Boost;
L_Supply_100_Req := GVL_COMMAND_SHADOW.G_Supply_100_Req;
L_Exhaust_100_Req := GVL_COMMAND_SHADOW.G_Exhaust_100_Req;
L_Supply_80_Req := GVL_COMMAND_SHADOW.G_Supply_80_Req;
L_Vent_Stop_Req := GVL_COMMAND_SHADOW.G_Vent_Stop;

// Priority 1: SMOKE
IF GVL_STATE.G_Safety_Smoke_Latched THEN
    L_Vent_Stop_Req := TRUE;
    L_Vent_PV3_Boost_Req := FALSE;
    L_Supply_100_Req := FALSE;
    L_Supply_80_Req := FALSE;
    L_Exhaust_100_Req := FALSE;

// Priority 2: GAS
ELSIF GVL_STATE.G_Safety_Gas_Latched THEN
    L_Vent_PV3_Boost_Req := TRUE;
    L_Supply_100_Req := TRUE;
    L_Vent_Stop_Req := FALSE;

// Priority 3: CO
ELSIF GVL_HEALTH_BRIDGE.G_CO_Warning_Level OR GVL_HEALTH_BRIDGE.G_CO_Alarm_Level THEN
    L_Supply_80_Req := TRUE;
    L_Vent_Stop_Req := FALSE;
END_IF;

// Priority 4: DEGRADED
IF GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_DEGRADED THEN
    L_Vent_PV3_Boost_Req := FALSE;
    L_Supply_100_Req := FALSE;
    L_Exhaust_100_Req := FALSE;
    L_Supply_80_Req := TRUE;
END_IF;


// 11. Управление вентиляцией
fbVentilationManager(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_IsActivePLC := GVL_STATUS.G_Is_Active_PLC,
    VI_Outdoor_Temp := GVL_STATE.G_Outdoor_Temp,
    VI_Supply_Temps := GVL_STATE.G_Supply_Temps,
    VI_Room_Temps := GVL_STATE.G_Room_Temps,
    VI_Room_Humidities := GVL_STATE.G_Room_Hum,
    VI_Room_CO2 := GVL_STATE.G_Room_CO2,
    VI_Current_Scenario := GVL_STATUS.G_Current_Scenario,
    VI_System_Mode := GVL_STATE.G_System_Mode,
    VI_Config := GVL_CONFIG.G_HMI_Vent_Global_Config,
    VI_Fire_Alarm := GVL_STATE.G_Safety_Smoke_Latched,
    VI_Gas_Alarm := GVL_STATE.G_Safety_Gas_Latched,
    VI_PV3_Boost_Req := L_Vent_PV3_Boost_Req,
    VI_Supply_100_Req := L_Supply_100_Req,
    VI_Exhaust_100_Req := L_Exhaust_100_Req,
    VI_Supply_80_Req := L_Supply_80_Req,
    VI_Vent_Stop := L_Vent_Stop_Req,
    VI_IO_Modules_Online := GVL_STATUS.G_IO_Modules_Online,
    VI_Wet_Zone_Active := L_Wet_Zone_Active,
    VI_Rule_Actions := GVL_STATE.G_Rule_Actions,
    VO_Supply_Fans => L_Supply_Fans_Byte,
    VO_Exhaust_Fans => L_Exhaust_Fans_Byte,
    VO_Heater_Power => GVL_STATE.G_Vent_Heater_Power,
    VO_Status_Msg => GVL_STATUS.G_Vent_Status_Msg
);
// >>> BULK_SYNC_ANCHOR: PRG_Ventilation <<<


// Ventilation copy-out adapters
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SUPPLY_FANS DO
    GVL_STATE.G_Supply_Fans[L_i] := BYTE_TO_REAL(L_Supply_Fans_Byte[L_i]);
END_FOR;
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_EXHAUST_FANS DO
    GVL_STATE.G_Exhaust_Fans[L_i] := BYTE_TO_REAL(L_Exhaust_Fans_Byte[L_i]);
END_FOR;
