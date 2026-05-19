PROGRAM PRG_IO_Read_Discrete_02_Security_Openings
VAR
    L_i : INT;
    L_Map_Index : INT;
    L_Glass_Index : INT;
    L_Debounce_Time : TIME := T#100MS;

    fbDebounce_Security_Open : ARRAY[1..GVL_CONSTANTS.C_MAX_SECURITY_SENSORS] OF FB_System_Timer;
    fbDebounce_Security_Glass : ARRAY[1..GVL_CONSTANTS.C_MAX_SECURITY_SENSORS] OF FB_System_Timer;
    fbDebounce_Group_2F : FB_System_Timer;
END_VAR

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SECURITY_SENSORS DO
    fbDebounce_Security_Open[L_i](
        IN := GVL_IO.DI_Security_Open[L_i],
        PT := L_Debounce_Time,
        VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
    );

    fbDebounce_Security_Glass[L_i](
        IN := GVL_IO.DI_Security_Glass[L_i],
        PT := L_Debounce_Time,
        VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
    );
END_FOR;

fbDebounce_Group_2F(
    IN := GVL_IO.DI_Security_2F_Group,
    PT := L_Debounce_Time,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_DOOR_SENSORS DO
    IF GVL_CONFIG.G_Door_Map[L_i] > 0 AND GVL_CONFIG.G_Door_Map[L_i] <= GVL_CONSTANTS.C_MAX_SECURITY_SENSORS THEN
        GVL_STATE.G_Door_Sensors[L_i] := fbDebounce_Security_Open[GVL_CONFIG.G_Door_Map[L_i]].Q;
    END_IF;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_ZONES DO
    L_Map_Index := GVL_CONFIG.G_Window_Map[L_i];
    IF L_Map_Index > 0 THEN
        IF L_Map_Index <= GVL_CONSTANTS.C_MAX_SECURITY_SENSORS THEN
            GVL_STATE.G_Window_Sensors[L_i] := fbDebounce_Security_Open[L_Map_Index].Q;
        ELSE
            L_Glass_Index := L_Map_Index - GVL_CONSTANTS.C_MAX_SECURITY_SENSORS;
            IF (L_Glass_Index >= 1) AND (L_Glass_Index <= GVL_CONSTANTS.C_MAX_SECURITY_SENSORS) THEN
                GVL_STATE.G_Window_Sensors[L_i] := fbDebounce_Security_Glass[L_Glass_Index].Q;
            END_IF;
        END_IF;
    END_IF;
END_FOR;

GVL_STATE.G_Window_Sensors[16] := fbDebounce_Group_2F.Q;

// >>> BULK_SYNC_ANCHOR: PRG_IO_Read_Discrete_02_Security_Openings <<<
END_PROGRAM
