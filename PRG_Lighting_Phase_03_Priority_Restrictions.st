PROGRAM PRG_Lighting_Phase_03_Priority_Restrictions
VAR
    L_i : INT;
END_VAR

// Priority overrides after normal manager calculation:
// Evacuation > Fire > Security Alarm > Security Armed > Normal
IF GVL_STATE.G_Evacuation_Lighting_Active THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_LIGHT_ZONES DO
        CASE GVL_STATE.G_Evac_Guidance[L_i] OF
            -1:
                GVL_STATE.G_Lighting_Levels[L_i] := 0;
            1:
                GVL_STATE.G_Lighting_Levels[L_i] := 100;
        ELSE
            IF GVL_LIGHTING_RUNTIME_BUFFER.B_Evac_Blink_On THEN
                GVL_STATE.G_Lighting_Levels[L_i] := 100;
            ELSE
                GVL_STATE.G_Lighting_Levels[L_i] := 0;
            END_IF;
        END_CASE;
    END_FOR;
ELSIF GVL_LIGHTING_RUNTIME_BUFFER.B_Fire_Alarm_Active THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_LIGHT_ZONES DO
        GVL_STATE.G_Lighting_Levels[L_i] := 100;
    END_FOR;
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BLINDS DO
        GVL_STATE.G_Blinds_Positions[L_i] := 100;
    END_FOR;
ELSIF GVL_LIGHTING_RUNTIME_BUFFER.B_Security_Alarm THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_LIGHT_ZONES DO
        GVL_STATE.G_Lighting_Levels[L_i] := 100;
    END_FOR;
ELSIF GVL_LIGHTING_RUNTIME_BUFFER.B_Security_Armed THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_LIGHT_ZONES DO
        GVL_STATE.G_Lighting_Levels[L_i] := 0;
    END_FOR;
END_IF;

// Distributed execution/projection restriction.
// If manager execution or output projection is blocked, clear non-emergency lighting state
// so publication cannot reuse stale values from a previous scan.
IF (
        NOT GVL_LIGHTING_RUNTIME_BUFFER.B_Distributed_Execute_Allowed
        OR NOT GVL_LIGHTING_RUNTIME_BUFFER.B_Distributed_Projection_Allowed
   )
   AND NOT GVL_LIGHTING_RUNTIME_BUFFER.B_Emergency_Lighting_Override THEN

    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_LIGHT_ZONES DO
        GVL_STATE.G_Lighting_Levels[L_i] := 0;
    END_FOR;

    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BLINDS DO
        GVL_STATE.G_Blinds_Positions[L_i] := 100;
    END_FOR;

    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SOCKETS DO
        GVL_STATE.G_Socket_States[L_i] := FALSE;
    END_FOR;

END_IF;

// >>> BULK_SYNC_ANCHOR: PRG_Lighting_Phase_03_Priority_Restrictions <<<
END_PROGRAM
