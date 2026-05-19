PROGRAM PRG_IO_Read_Discrete_01_Lighting_Sockets
VAR
    L_i : INT;
    L_Debounce_Time : TIME := T#100MS;

    fbDebounce_Switches : ARRAY[1..GVL_CONSTANTS.C_MAX_LIGHT_ZONES] OF FB_System_Timer;
    fbDebounce_Motion : ARRAY[1..GVL_CONSTANTS.C_MAX_LIGHT_ZONES] OF FB_System_Timer;
END_VAR

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_LIGHT_ZONES DO
    fbDebounce_Switches[L_i](
        IN := GVL_IO.DI_Lighting_Switches[L_i],
        PT := L_Debounce_Time,
        VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
    );
    GVL_STATE.G_Physical_Switches[L_i] := fbDebounce_Switches[L_i].Q;

    fbDebounce_Motion[L_i](
        IN := GVL_IO.DI_Motion_Sensors[L_i],
        PT := L_Debounce_Time,
        VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
    );
    GVL_STATE.G_Motion_Sensors[L_i] := fbDebounce_Motion[L_i].Q;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SOCKETS DO
    GVL_STATE.G_Socket_Switches[L_i] := GVL_IO.DI_Socket_Switches[L_i];
END_FOR;

// >>> BULK_SYNC_ANCHOR: PRG_IO_Read_Discrete_01_Lighting_Sockets <<<
END_PROGRAM
