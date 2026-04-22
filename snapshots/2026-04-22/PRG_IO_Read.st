PROGRAM PRG_IO_Read
VAR
    L_i : INT;
    L_Debounce_Time : TIME := T#100MS;
    
    fbDebounce_Switches : ARRAY[1..8] OF FB_System_Timer;
    fbDebounce_Motion : ARRAY[1..8] OF FB_System_Timer;
    fbDebounce_Security_Open : ARRAY[1..GVL_CONSTANTS.C_MAX_SECURITY_SENSORS] OF FB_System_Timer;
    fbDebounce_Security_Glass : ARRAY[1..GVL_CONSTANTS.C_MAX_SECURITY_SENSORS] OF FB_System_Timer;
    fbDebounce_Flood : ARRAY[1..GVL_CONSTANTS.C_MAX_FLOOD_SENSORS] OF FB_System_Timer;
    fbDebounce_Smoke : ARRAY[1..GVL_CONSTANTS.C_MAX_SMOKE_SENSORS] OF FB_System_Timer;
    fbDebounce_Group_2F : FB_System_Timer;
    
    fbIO_Watchdog_1 : FB_IO_Module_Watchdog;
    fbIO_Watchdog_2 : FB_IO_Module_Watchdog;
    L_IO_Error_Active : BOOL;
END_VAR

// 0. КОНТРОЛЬ СВЯЗИ С МОДУЛЯМИ ВВОДА-ВЫВОДА (Watchdog)
fbIO_Watchdog_1(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Module_ID := 1,
    VI_Heartbeat_Signal := GVL_IO.DI_Module_1_Heartbeat,
    VI_Timeout_MS := 2000
);

fbIO_Watchdog_2(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Module_ID := 2,
    VI_Heartbeat_Signal := GVL_IO.DI_Module_2_Heartbeat,
    VI_Timeout_MS := 2000
);

GVL_STATUS.G_IO_Modules_Online[1] := fbIO_Watchdog_1.VO_Module_Online;
GVL_STATUS.G_IO_Modules_Online[2] := fbIO_Watchdog_2.VO_Module_Online;

L_IO_Error_Active := fbIO_Watchdog_1.VO_Error_Active OR fbIO_Watchdog_2.VO_Error_Active;

IF L_IO_Error_Active THEN
    GVL_COMMAND.G_Gas_Valve_Close := TRUE;
    GVL_COMMAND.G_Close_Valve_35 := TRUE;
    GVL_COMMAND.G_Close_Valve_36 := TRUE;
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO GVL_STATE.G_Manifold_Pumps[L_i] := FALSE; END_FOR;
END_IF;

// 1. ЧТЕНИЕ И ФИЛЬТРАЦИЯ ВХОДОВ
FOR L_i := 1 TO 8 DO
    fbDebounce_Switches[L_i](IN := GVL_IO.DI_Lighting_Switches[L_i], PT := L_Debounce_Time, VI_System_Time_MS := GVL_STATUS.G_System_Time_MS);
    GVL_STATE.G_Physical_Switches[L_i] := fbDebounce_Switches[L_i].Q;
    
    fbDebounce_Motion[L_i](IN := GVL_IO.DI_Motion_Sensors[L_i], PT := L_Debounce_Time, VI_System_Time_MS := GVL_STATUS.G_System_Time_MS);
    GVL_STATE.G_Motion_Sensors[L_i] := fbDebounce_Motion[L_i].Q;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SOCKETS DO
    // В текущей концепции локальные физические выключатели розеток не используются.
    // Состояние оставляем FALSE для обратной совместимости структуры.
    GVL_STATE.G_Socket_Switches[L_i] := FALSE;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SECURITY_SENSORS DO
    fbDebounce_Security_Open[L_i](IN := GVL_IO.DI_Security_Open[L_i], PT := L_Debounce_Time, VI_System_Time_MS := GVL_STATUS.G_System_Time_MS);
    fbDebounce_Security_Glass[L_i](IN := GVL_IO.DI_Security_Glass[L_i], PT := L_Debounce_Time, VI_System_Time_MS := GVL_STATUS.G_System_Time_MS);
END_FOR;
fbDebounce_Group_2F(IN := GVL_IO.DI_Security_2F_Group, PT := L_Debounce_Time, VI_System_Time_MS := GVL_STATUS.G_System_Time_MS);

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_DOOR_SENSORS DO
    IF GVL_CONFIG.G_Door_Map[L_i] > 0 AND GVL_CONFIG.G_Door_Map[L_i] <= GVL_CONSTANTS.C_MAX_SECURITY_SENSORS THEN
        GVL_STATE.G_Door_Sensors[L_i] := fbDebounce_Security_Open[GVL_CONFIG.G_Door_Map[L_i]].Q;
    END_IF;
END_FOR;

FOR L_i := 1 TO 8 DO
    IF GVL_CONFIG.G_Window_Map[L_i] > 0 THEN
        IF GVL_CONFIG.G_Window_Map[L_i] <= GVL_CONSTANTS.C_MAX_SECURITY_SENSORS THEN
            GVL_STATE.G_Window_Sensors[L_i] := fbDebounce_Security_Open[GVL_CONFIG.G_Window_Map[L_i]].Q;
        ELSIF GVL_CONFIG.G_Window_Map[L_i] <= (GVL_CONSTANTS.C_MAX_SECURITY_SENSORS * 2) THEN
            GVL_STATE.G_Window_Sensors[L_i] := fbDebounce_Security_Glass[GVL_CONFIG.G_Window_Map[L_i] - GVL_CONSTANTS.C_MAX_SECURITY_SENSORS].Q;
        END_IF;
    END_IF;
END_FOR;
GVL_STATE.G_Window_Sensors[16] := fbDebounce_Group_2F.Q;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_FLOOD_SENSORS DO
    fbDebounce_Flood[L_i](IN := GVL_IO.DI_Flood_Sensors[L_i], PT := L_Debounce_Time, VI_System_Time_MS := GVL_STATUS.G_System_Time_MS);
    GVL_STATE.G_Water_Sensors[L_i] := fbDebounce_Flood[L_i].Q;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SMOKE_SENSORS DO
    fbDebounce_Smoke[L_i](IN := GVL_IO.DI_Smoke_Sensors[L_i], PT := L_Debounce_Time, VI_System_Time_MS := GVL_STATUS.G_System_Time_MS);
    GVL_STATE.G_Smoke_Sensors[L_i] := fbDebounce_Smoke[L_i].Q;
END_FOR;

IF GVL_IO.AI_Temp_Outdoor.wStatus = 0 THEN
    GVL_STATE.G_Outdoor_Temp := GVL_IO.AI_Temp_Outdoor.rValue;
END_IF;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SUPPLY_TEMPS DO
    IF GVL_IO.AI_Supply_Temps[L_i].wStatus = 0 THEN
        GVL_STATE.G_Supply_Temps[L_i] := GVL_IO.AI_Supply_Temps[L_i].rValue;
    END_IF;
END_FOR;

FOR L_i := 1 TO 8 DO
    GVL_STATE.G_Room_Hum[L_i] := GVL_IO.AI_Room_Hum[L_i];
    GVL_STATE.G_Room_CO2[L_i] := GVL_IO.AI_Room_CO2[L_i];
END_FOR;
FOR L_i := 1 TO 8 DO
    IF GVL_CONFIG.G_FloorTemp_Map[L_i] > 0 AND GVL_CONFIG.G_FloorTemp_Map[L_i] <= 8 THEN
        GVL_STATE.G_Floor_Temps[L_i] := GVL_IO.AI_Floor_Temps[GVL_CONFIG.G_FloorTemp_Map[L_i]];
    END_IF;
    IF GVL_CONFIG.G_RoomTemp_Map[L_i] > 0 AND GVL_CONFIG.G_RoomTemp_Map[L_i] <= 8 THEN
        GVL_STATE.G_Room_Temps[L_i] := GVL_IO.AI_Room_Temps[GVL_CONFIG.G_RoomTemp_Map[L_i]];
    END_IF;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    GVL_STATE.G_Manifold_Pressures[L_i] := INT_TO_REAL(GVL_IO.AI_Manifold_Pressures[L_i]) / 10.0;
    GVL_STATE.G_Manifold_Currents[L_i] := INT_TO_REAL(GVL_IO.AI_Manifold_Currents[L_i]) / 100.0;
    IF GVL_IO.AI_Manifold_Temps_Supply[L_i].wStatus = 0 THEN
        GVL_STATE.G_Manifold_T_Supply[L_i] := GVL_IO.AI_Manifold_Temps_Supply[L_i].rValue;
    END_IF;
    GVL_STATE.G_Manifold_T_Return[L_i] := INT_TO_REAL(GVL_IO.AI_Manifold_Temps_Return[L_i]) / 10.0;
    GVL_STATE.G_Manifold_End_Switches[L_i] := GVL_IO.DI_Manifold_End_Switches[L_i];
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_METHANE_SENSORS DO
    IF GVL_IO.AI_Methane_LEL[L_i].wStatus = 0 THEN
        GVL_STATE.G_Methane_Sensors[L_i] := GVL_IO.AI_Methane_LEL[L_i].rValue;
    END_IF;
END_FOR;
GVL_STATE.G_Boiler_Flame := GVL_IO.AI_Boiler_Flame_Status;
GVL_STATE.G_Boiler_Error := GVL_IO.DI_Boiler_Error;
// --- SAFETY bootstrap mapping (temporary, will be normalized later if dedicated managers exist) ---
GVL_STATE.G_Safety_Gas_Alarm := FALSE;
GVL_STATE.G_Safety_Leak_Alarm := FALSE;
GVL_STATE.G_Safety_Smoke_Alarm := FALSE;

// Временное безопасное поведение:
// до подключения реального драйвера/шлюза OpenTherm считаем канал котла недоступным.
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BOILERS DO
    GVL_STATE.G_Boiler_OT_Online[L_i] := FALSE;
END_FOR;
GVL_STATE.G_CO_Sensors := GVL_IO.AI_CO_PPM;

GVL_STATE.G_DHW_Temp := GVL_IO.AI_DHW_Temp;
GVL_STATE.G_DHW_Pressure := GVL_IO.AI_DHW_Pressure;

// Water zonal valve feedback mapping
GVL_STATE.G_Water_Zone_Open_FB := GVL_IO.DI_Water_Zone_Open_FB;
GVL_STATE.G_Water_Zone_Close_FB := GVL_IO.DI_Water_Zone_Close_FB;

GVL_STATUS.G_Diagnostics.Backup_Pump_Fault := FALSE;
GVL_STATUS.G_Diagnostics.Electric_Heater_Fault := FALSE;
// >>> BULK_SYNC_ANCHOR: PRG_IO_Read <<<
