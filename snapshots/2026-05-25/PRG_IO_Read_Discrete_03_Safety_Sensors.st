PROGRAM PRG_IO_Read_Discrete_03_Safety_Sensors
VAR
    L_i : INT;
    L_Debounce_Time : TIME := T#100MS;

    fbDebounce_Flood : ARRAY[1..GVL_CONSTANTS.C_MAX_FLOOD_SENSORS] OF FB_System_Timer;
    fbDebounce_Smoke : ARRAY[1..GVL_CONSTANTS.C_MAX_SMOKE_SENSORS] OF FB_System_Timer;
END_VAR

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_FLOOD_SENSORS DO
    fbDebounce_Flood[L_i](
        IN := GVL_IO.DI_Flood_Sensors[L_i],
        PT := L_Debounce_Time,
        VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
    );
    GVL_STATE.G_Water_Sensors[L_i] := fbDebounce_Flood[L_i].Q;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SMOKE_SENSORS DO
    fbDebounce_Smoke[L_i](
        IN := GVL_IO.DI_Smoke_Sensors[L_i],
        PT := L_Debounce_Time,
        VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
    );
    GVL_STATE.G_Smoke_Sensors[L_i] := fbDebounce_Smoke[L_i].Q;
END_FOR;

// >>> BULK_SYNC_ANCHOR: PRG_IO_Read_Discrete_03_Safety_Sensors <<<
END_PROGRAM
