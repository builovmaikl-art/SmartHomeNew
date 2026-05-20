FUNCTION_BLOCK FB_Socket_Manager
VAR_INPUT
    VI_System_Time_MS : UDINT;
    VI_IsActivePLC : BOOL;
    VI_Scenario : E_SCENARIO_TYPE;
    VI_Fire_Alarm : BOOL;
    VI_Flood_Alarm : BOOL;
    VI_Security_Armed : BOOL;
END_VAR
VAR_IN_OUT
    VI_Manual_Override : ARRAY[1..GVL_CONSTANTS.C_MAX_SOCKETS] OF BOOL;
    VI_Physical_Switches : ARRAY[1..GVL_CONSTANTS.C_MAX_SOCKETS] OF BOOL;
    VI_Rule_Actions : ARRAY[1..GVL_CONSTANTS.C_MAX_RULES] OF ST_Rule_Action;
    VI_IO_Modules_Online : ARRAY[1..GVL_CONSTANTS.C_MAX_MODULES] OF BOOL;
END_VAR
VAR_OUTPUT
    VO_Socket_States : ARRAY[1..GVL_CONSTANTS.C_MAX_SOCKETS] OF BOOL;
    VO_Internal_States : ARRAY[1..GVL_CONSTANTS.C_MAX_SOCKETS] OF BOOL;
END_VAR
VAR
    L_i : INT;
    L_j : INT;
    L_Rule_State : BOOL;
    L_Rule_Active : BOOL;
    L_Internal_State : ARRAY[1..GVL_CONSTANTS.C_MAX_SOCKETS] OF BOOL;
    L_Manual_Trig : ARRAY[1..GVL_CONSTANTS.C_MAX_SOCKETS] OF R_TRIG;
    L_Restore_Trig : R_TRIG;
END_VAR

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SOCKETS DO
    VO_Socket_States[L_i] := FALSE;
    VO_Internal_States[L_i] := L_Internal_State[L_i];
END_FOR;

IF NOT VI_IsActivePLC THEN
    RETURN;
END_IF;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MODULES DO
    IF NOT VI_IO_Modules_Online[L_i] THEN
        RETURN;
    END_IF;
END_FOR;

L_Restore_Trig(CLK := GVL_AWAY_RESTORE.G_Restore_Active AND GVL_AWAY_RESTORE.G_Snapshot_Valid);
IF L_Restore_Trig.Q AND NOT VI_Fire_Alarm AND NOT VI_Flood_Alarm THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SOCKETS DO
        L_Internal_State[L_i] := GVL_AWAY_RESTORE.G_Socket_States[L_i];
    END_FOR;
END_IF;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SOCKETS DO
    L_Rule_Active := FALSE;
    L_Rule_State := FALSE;
    
    L_Manual_Trig[L_i](CLK := VI_Manual_Override[L_i]);
    
    IF L_Manual_Trig[L_i].Q THEN
        L_Internal_State[L_i] := NOT L_Internal_State[L_i];
    END_IF;

    FOR L_j := 1 TO GVL_CONSTANTS.C_MAX_RULES DO
        IF VI_Rule_Actions[L_j].Active AND VI_Rule_Actions[L_j].Target_ID = L_i THEN
            IF VI_Rule_Actions[L_j].Action_Type = E_Rule_Action_Type.ACTION_SET_SOCKET THEN
                L_Rule_Active := TRUE;
                L_Rule_State := (VI_Rule_Actions[L_j].Value > 0.5);
                L_Internal_State[L_i] := L_Rule_State;
            ELSIF VI_Rule_Actions[L_j].Action_Type = E_Rule_Action_Type.ACTION_TOGGLE_SOCKET AND VI_Rule_Actions[L_j].Triggered THEN
                L_Internal_State[L_i] := NOT L_Internal_State[L_i];
            END_IF;
        END_IF;
    END_FOR;

    IF VI_Fire_Alarm OR VI_Flood_Alarm THEN
        IF L_i > 4 THEN
            VO_Socket_States[L_i] := FALSE;
        ELSE
            VO_Socket_States[L_i] := L_Internal_State[L_i];
        END_IF;
    ELSIF VI_Scenario = E_SCENARIO_TYPE.SCENARIO_AWAY OR VI_Security_Armed THEN
        IF L_i > 4 THEN
            VO_Socket_States[L_i] := FALSE;
        ELSE
            VO_Socket_States[L_i] := L_Internal_State[L_i];
        END_IF;
    ELSE
        IF L_Rule_Active THEN
            VO_Socket_States[L_i] := L_Rule_State;
        ELSE
            VO_Socket_States[L_i] := L_Internal_State[L_i];
        END_IF;
    END_IF;
END_FOR;

VO_Internal_States := L_Internal_State;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Socket_Manager <<<