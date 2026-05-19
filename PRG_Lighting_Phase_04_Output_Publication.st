PROGRAM PRG_Lighting_Phase_04_Output_Publication
VAR
    L_i : INT;
    L_Wet_Zone_Any_Active : BOOL;
END_VAR

GVL_LIGHTING_RUNTIME.G_Runtime_Required := FALSE;
GVL_LIGHTING_RUNTIME.G_Runtime_Executed := TRUE;
GVL_LIGHTING_RUNTIME.G_Runtime_Idle_By_Design := FALSE;
GVL_LIGHTING_RUNTIME.G_Runtime_Blocked_By_Distributed_Gates := FALSE;
GVL_LIGHTING_RUNTIME.G_Emergency_Override_Active := GVL_LIGHTING_RUNTIME_BUFFER.B_Emergency_Lighting_Override;
GVL_LIGHTING_RUNTIME.G_Any_Light_Active := FALSE;
GVL_LIGHTING_RUNTIME.G_Any_Blind_Not_Safe_Open := FALSE;
GVL_LIGHTING_RUNTIME.G_Any_Socket_Active := FALSE;
GVL_LIGHTING_RUNTIME.G_Last_Update_MS := GVL_STATUS.G_System_Time_MS;

// Publish wet-zone activity from the final lighting state seen by IO_Write.
L_Wet_Zone_Any_Active := FALSE;
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_LIGHT_ZONES DO
    IF GVL_CONFIG.G_Wet_Zone_Map[L_i] AND (GVL_STATE.G_Lighting_Levels[L_i] > 10) THEN
        L_Wet_Zone_Any_Active := TRUE;
    END_IF;

    IF GVL_STATE.G_Lighting_Levels[L_i] > 0 THEN
        GVL_LIGHTING_RUNTIME.G_Any_Light_Active := TRUE;
    END_IF;
END_FOR;
GVL_STATUS.G_Wet_Zone_Light_Active := L_Wet_Zone_Any_Active;

// Domain output projection.
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_LIGHT_ZONES DO
    GVL_LIGHTING_OUTPUT.AO_Lighting_Levels[L_i] := BYTE_TO_UINT(GVL_STATE.G_Lighting_Levels[L_i]) * 10;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BLINDS DO
    IF GVL_STATE.G_Blinds_Positions[L_i] < 100 THEN
        GVL_LIGHTING_RUNTIME.G_Any_Blind_Not_Safe_Open := TRUE;
    END_IF;

    GVL_LIGHTING_OUTPUT.AO_Blinds_Positions[L_i] := BYTE_TO_UINT(GVL_STATE.G_Blinds_Positions[L_i]) * 10;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SOCKETS DO
    IF GVL_STATE.G_Socket_States[L_i] THEN
        GVL_LIGHTING_RUNTIME.G_Any_Socket_Active := TRUE;
    END_IF;

    GVL_LIGHTING_OUTPUT.DO_Sockets[L_i] := GVL_STATE.G_Socket_States[L_i];
END_FOR;

GVL_LIGHTING_RUNTIME.G_Runtime_Blocked_By_Distributed_Gates :=
    NOT GVL_LIGHTING_RUNTIME_BUFFER.B_Distributed_Projection_Allowed
    AND NOT GVL_LIGHTING_RUNTIME_BUFFER.B_Emergency_Lighting_Override;

GVL_LIGHTING_RUNTIME.G_Runtime_Required :=
    GVL_LIGHTING_RUNTIME.G_Emergency_Override_Active
    OR GVL_LIGHTING_RUNTIME.G_Any_Light_Active
    OR GVL_LIGHTING_RUNTIME.G_Any_Blind_Not_Safe_Open
    OR GVL_LIGHTING_RUNTIME.G_Any_Socket_Active
    OR GVL_LIGHTING_RUNTIME_BUFFER.B_Security_Armed
    OR GVL_LIGHTING_RUNTIME_BUFFER.B_Security_Alarm;

GVL_LIGHTING_RUNTIME.G_Runtime_Idle_By_Design :=
    NOT GVL_LIGHTING_RUNTIME.G_Runtime_Required;

IF GVL_LIGHTING_RUNTIME.G_Runtime_Blocked_By_Distributed_Gates THEN
    GVL_LIGHTING_RUNTIME.G_Status_Code := 2;
    GVL_LIGHTING_RUNTIME.G_Status_Text := 'Lighting runtime blocked by distributed gates';
ELSIF GVL_LIGHTING_RUNTIME.G_Runtime_Idle_By_Design THEN
    GVL_LIGHTING_RUNTIME.G_Status_Code := 0;
    GVL_LIGHTING_RUNTIME.G_Status_Text := 'Lighting runtime idle by design';
ELSE
    GVL_LIGHTING_RUNTIME.G_Status_Code := 1;
    GVL_LIGHTING_RUNTIME.G_Status_Text := 'Lighting runtime active';
END_IF;

// >>> BULK_SYNC_ANCHOR: PRG_Lighting_Phase_04_Output_Publication <<<
END_PROGRAM
