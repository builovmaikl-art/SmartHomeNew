PROGRAM PRG_Lighting_Phase_04_Output_Publication
VAR
    L_i : INT;
    L_Wet_Zone_Any_Active : BOOL;
END_VAR

// Publish wet-zone activity from the final lighting state seen by IO_Write.
L_Wet_Zone_Any_Active := FALSE;
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_LIGHT_ZONES DO
    IF GVL_CONFIG.G_Wet_Zone_Map[L_i] AND (GVL_STATE.G_Lighting_Levels[L_i] > 10) THEN
        L_Wet_Zone_Any_Active := TRUE;
    END_IF;
END_FOR;
GVL_STATUS.G_Wet_Zone_Light_Active := L_Wet_Zone_Any_Active;

// Domain output projection.
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_LIGHT_ZONES DO
    GVL_LIGHTING_OUTPUT.AO_Lighting_Levels[L_i] := BYTE_TO_UINT(GVL_STATE.G_Lighting_Levels[L_i]) * 10;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BLINDS DO
    GVL_LIGHTING_OUTPUT.AO_Blinds_Positions[L_i] := BYTE_TO_UINT(GVL_STATE.G_Blinds_Positions[L_i]) * 10;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SOCKETS DO
    GVL_LIGHTING_OUTPUT.DO_Sockets[L_i] := GVL_STATE.G_Socket_States[L_i];
END_FOR;

// >>> BULK_SYNC_ANCHOR: PRG_Lighting_Phase_04_Output_Publication <<<
END_PROGRAM
