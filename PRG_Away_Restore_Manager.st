PROGRAM PRG_Away_Restore_Manager
VAR
    L_i : INT;
    L_Away_Active_Prev : BOOL := FALSE;
    L_Away_Level_Prev : BYTE := 0;
    L_Take_Snapshot : BOOL;
    L_Start_Restore : BOOL;
END_VAR

L_Take_Snapshot :=
    GVL_POLICY.G_Away_Active AND
    (GVL_POLICY.G_Away_Level = 1) AND
    (NOT L_Away_Active_Prev);

IF L_Take_Snapshot THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_LIGHT_ZONES DO
        GVL_AWAY_RESTORE.G_Lighting_Levels[L_i] := GVL_STATE.G_Lighting_Levels[L_i];
    END_FOR;

    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SOCKETS DO
        GVL_AWAY_RESTORE.G_Socket_States[L_i] := GVL_STATE.G_Socket_States[L_i];
    END_FOR;

    GVL_AWAY_RESTORE.G_Snapshot_Valid := TRUE;
    GVL_AWAY_RESTORE.G_Snapshot_Taken_MS := GVL_TIME_SERVICE.G_Now_MS;
    GVL_AWAY_RESTORE.G_Restore_Done := FALSE;
END_IF;

L_Start_Restore :=
    GVL_POLICY.G_Away_Restore_Requested AND
    GVL_AWAY_RESTORE.G_Snapshot_Valid;

IF L_Start_Restore THEN
    GVL_AWAY_RESTORE.G_Restore_Active := TRUE;
    GVL_AWAY_RESTORE.G_Restore_Started_MS := GVL_TIME_SERVICE.G_Now_MS;
    GVL_AWAY_RESTORE.G_Restore_Done := FALSE;
END_IF;

IF GVL_AWAY_RESTORE.G_Restore_Active THEN
    GVL_AWAY_RESTORE.G_Restore_Progress := GVL_POLICY.G_Away_Restore_Progress;

    IF NOT GVL_POLICY.G_Away_Restore_Active THEN
        GVL_AWAY_RESTORE.G_Restore_Progress := 1.0;
        GVL_AWAY_RESTORE.G_Restore_Active := FALSE;
        GVL_AWAY_RESTORE.G_Restore_Done := TRUE;
        GVL_AWAY_RESTORE.G_Snapshot_Valid := FALSE;
    END_IF;
ELSE
    IF NOT GVL_AWAY_RESTORE.G_Restore_Done THEN
        GVL_AWAY_RESTORE.G_Restore_Progress := 0.0;
    END_IF;
END_IF;

L_Away_Active_Prev := GVL_POLICY.G_Away_Active;
L_Away_Level_Prev := GVL_POLICY.G_Away_Level;

END_PROGRAM