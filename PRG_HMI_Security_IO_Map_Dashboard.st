PROGRAM PRG_HMI_Security_IO_Map_Dashboard
VAR
    L_i : INT;
    L_Map_Index : INT;
    L_Glass_Index : INT;
END_VAR

GVL_HMI_SECURITY_IO_MAP.G_Any_Invalid_Map := FALSE;
GVL_HMI_SECURITY_IO_MAP.G_Group_2F_Active := GVL_IO.DI_Security_2F_Group;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_DOOR_SENSORS DO
    L_Map_Index := GVL_CONFIG.G_Door_Map[L_i];
    GVL_HMI_SECURITY_IO_MAP.G_Door_Map[L_i] := L_Map_Index;
    GVL_HMI_SECURITY_IO_MAP.G_Door_Map_Valid[L_i] :=
        (L_Map_Index > 0) AND (L_Map_Index <= GVL_CONSTANTS.C_MAX_SECURITY_SENSORS);

    IF GVL_HMI_SECURITY_IO_MAP.G_Door_Map_Valid[L_i] THEN
        GVL_HMI_SECURITY_IO_MAP.G_Door_Raw_Open[L_i] := GVL_IO.DI_Security_Open[L_Map_Index];
    ELSE
        GVL_HMI_SECURITY_IO_MAP.G_Door_Raw_Open[L_i] := FALSE;
        GVL_HMI_SECURITY_IO_MAP.G_Any_Invalid_Map := TRUE;
    END_IF;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_ZONES DO
    L_Map_Index := GVL_CONFIG.G_Window_Map[L_i];
    GVL_HMI_SECURITY_IO_MAP.G_Window_Map[L_i] := L_Map_Index;
    GVL_HMI_SECURITY_IO_MAP.G_Window_Uses_Open_Input[L_i] := FALSE;
    GVL_HMI_SECURITY_IO_MAP.G_Window_Uses_Glass_Input[L_i] := FALSE;
    GVL_HMI_SECURITY_IO_MAP.G_Window_Overridden_By_2F_Group[L_i] := (L_i = 16);
    GVL_HMI_SECURITY_IO_MAP.G_Window_Raw_Open[L_i] := FALSE;

    IF L_Map_Index > 0 THEN
        IF L_Map_Index <= GVL_CONSTANTS.C_MAX_SECURITY_SENSORS THEN
            GVL_HMI_SECURITY_IO_MAP.G_Window_Map_Valid[L_i] := TRUE;
            GVL_HMI_SECURITY_IO_MAP.G_Window_Uses_Open_Input[L_i] := TRUE;
            GVL_HMI_SECURITY_IO_MAP.G_Window_Raw_Open[L_i] := GVL_IO.DI_Security_Open[L_Map_Index];
        ELSE
            L_Glass_Index := L_Map_Index - GVL_CONSTANTS.C_MAX_SECURITY_SENSORS;
            IF (L_Glass_Index >= 1) AND (L_Glass_Index <= GVL_CONSTANTS.C_MAX_SECURITY_SENSORS) THEN
                GVL_HMI_SECURITY_IO_MAP.G_Window_Map_Valid[L_i] := TRUE;
                GVL_HMI_SECURITY_IO_MAP.G_Window_Uses_Glass_Input[L_i] := TRUE;
                GVL_HMI_SECURITY_IO_MAP.G_Window_Raw_Open[L_i] := GVL_IO.DI_Security_Glass[L_Glass_Index];
            ELSE
                GVL_HMI_SECURITY_IO_MAP.G_Window_Map_Valid[L_i] := FALSE;
                GVL_HMI_SECURITY_IO_MAP.G_Any_Invalid_Map := TRUE;
            END_IF;
        END_IF;
    ELSE
        GVL_HMI_SECURITY_IO_MAP.G_Window_Map_Valid[L_i] := FALSE;
        GVL_HMI_SECURITY_IO_MAP.G_Any_Invalid_Map := TRUE;
    END_IF;
END_FOR;

IF GVL_HMI_SECURITY_IO_MAP.G_Any_Invalid_Map THEN
    GVL_HMI_SECURITY_IO_MAP.G_Status_Text := 'Security IO map has invalid entries';
ELSE
    GVL_HMI_SECURITY_IO_MAP.G_Status_Text := 'Security IO map valid';
END_IF;

// >>> BULK_SYNC_ANCHOR: PRG_HMI_Security_IO_Map_Dashboard <<<
END_PROGRAM
