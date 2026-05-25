FUNCTION_BLOCK FB_Outdoor_Lighting_Manager
VAR_INPUT
    VI_IsActivePLC : BOOL;
    VI_Current_Scenario : E_SCENARIO_TYPE;
    VI_Security_Armed : BOOL;
    VI_Is_Night : BOOL;
    VI_Time_Of_Day_MS : UDINT;
END_VAR
VAR_IN_OUT
    VIO_Rule_Actions : ARRAY[1..GVL_CONSTANTS.C_MAX_RULES] OF ST_Rule_Action;
    VI_Motion_Sensors : ARRAY[1..GVL_CONSTANTS.C_MAX_LIGHT_ZONES] OF BOOL;
END_VAR
VAR
    L_Zone : INT;
    L_Slot : INT;
    L_Light_Index : INT;
    L_Motion_Index : INT;
    L_Socket_Index : INT;
    L_Target_Level : BYTE;
    L_Target_Socket : BOOL;
    L_Dark : BOOL;
    L_Economy : BOOL;
    L_Party : BOOL;
    L_Security : BOOL;
    L_Any_Motion : BOOL;
END_VAR

GVL_OUTDOOR_LIGHTING.G_Outdoor_Dark_Active := FALSE;
GVL_OUTDOOR_LIGHTING.G_Outdoor_Economy_Active := FALSE;
GVL_OUTDOOR_LIGHTING.G_Outdoor_Party_Active := FALSE;
GVL_OUTDOOR_LIGHTING.G_Outdoor_Security_Active := FALSE;
GVL_OUTDOOR_LIGHTING.G_Outdoor_Status_Text := 'OUTDOOR DISABLED';

FOR L_Zone := 1 TO GVL_CONSTANTS.C_MAX_OUTDOOR_ZONES DO
    GVL_OUTDOOR_LIGHTING.G_Outdoor_Light_Level[L_Zone] := 0;
    GVL_OUTDOOR_LIGHTING.G_Outdoor_Socket_State[L_Zone] := FALSE;
END_FOR;

IF (NOT VI_IsActivePLC) OR (NOT GVL_OUTDOOR_LIGHTING.G_Outdoor_Enabled) THEN
    RETURN;
END_IF;

L_Dark := FALSE;
IF GVL_OUTDOOR_LIGHTING.G_Outdoor_Fallback_To_Night THEN
    L_Dark := VI_Is_Night;
END_IF;
IF GVL_OUTDOOR_LIGHTING.G_Outdoor_Use_Lux_Sensor AND GVL_STATE.G_Ambient_Lux_Valid THEN
    L_Dark := L_Dark OR (GVL_STATE.G_Ambient_Lux < GVL_OUTDOOR_LIGHTING.G_Outdoor_Lux_Threshold);
END_IF;

IF GVL_OUTDOOR_LIGHTING.G_Outdoor_Economy_Start_MS <= GVL_OUTDOOR_LIGHTING.G_Outdoor_Economy_End_MS THEN
    L_Economy := (VI_Time_Of_Day_MS >= GVL_OUTDOOR_LIGHTING.G_Outdoor_Economy_Start_MS) AND (VI_Time_Of_Day_MS < GVL_OUTDOOR_LIGHTING.G_Outdoor_Economy_End_MS);
ELSE
    L_Economy := (VI_Time_Of_Day_MS >= GVL_OUTDOOR_LIGHTING.G_Outdoor_Economy_Start_MS) OR (VI_Time_Of_Day_MS < GVL_OUTDOOR_LIGHTING.G_Outdoor_Economy_End_MS);
END_IF;

L_Party := (VI_Current_Scenario = E_SCENARIO_TYPE.SCENARIO_PARTY);
L_Any_Motion := FALSE;
FOR L_Zone := 1 TO GVL_CONSTANTS.C_MAX_OUTDOOR_ZONES DO
    L_Motion_Index := GVL_OUTDOOR_LIGHTING.G_Outdoor_Motion_Zone_Index[L_Zone];
    IF (L_Motion_Index >= 1) AND (L_Motion_Index <= GVL_CONSTANTS.C_MAX_LIGHT_ZONES) THEN
        L_Any_Motion := L_Any_Motion OR VI_Motion_Sensors[L_Motion_Index];
    END_IF;
END_FOR;
L_Security := VI_Security_Armed AND L_Any_Motion;

GVL_OUTDOOR_LIGHTING.G_Outdoor_Dark_Active := L_Dark;
GVL_OUTDOOR_LIGHTING.G_Outdoor_Economy_Active := L_Dark AND L_Economy;
GVL_OUTDOOR_LIGHTING.G_Outdoor_Party_Active := L_Party;
GVL_OUTDOOR_LIGHTING.G_Outdoor_Security_Active := L_Security;

FOR L_Zone := 1 TO GVL_CONSTANTS.C_MAX_OUTDOOR_ZONES DO
    IF GVL_OUTDOOR_LIGHTING.G_Outdoor_Manual_Mode[L_Zone] THEN
        L_Target_Level := GVL_OUTDOOR_LIGHTING.G_Outdoor_Manual_Light_Level[L_Zone];
        L_Target_Socket := GVL_OUTDOOR_LIGHTING.G_Outdoor_Manual_Socket_State[L_Zone];
    ELSIF L_Party THEN
        L_Target_Level := GVL_OUTDOOR_LIGHTING.G_Outdoor_Party_Level;
        L_Target_Socket := GVL_OUTDOOR_LIGHTING.G_Outdoor_Sockets_Enabled AND GVL_OUTDOOR_LIGHTING.G_Outdoor_Sockets_On_In_Party;
    ELSIF L_Security THEN
        L_Target_Level := GVL_OUTDOOR_LIGHTING.G_Outdoor_Security_Level;
        L_Target_Socket := GVL_OUTDOOR_LIGHTING.G_Outdoor_Sockets_Enabled AND NOT GVL_OUTDOOR_LIGHTING.G_Outdoor_Sockets_Off_In_Security;
    ELSIF L_Dark AND L_Economy THEN
        L_Target_Level := GVL_OUTDOOR_LIGHTING.G_Outdoor_Economy_Level;
        L_Target_Socket := FALSE;
    ELSIF L_Dark THEN
        L_Target_Level := GVL_OUTDOOR_LIGHTING.G_Outdoor_Auto_Level;
        L_Target_Socket := GVL_OUTDOOR_LIGHTING.G_Outdoor_Sockets_Enabled AND GVL_OUTDOOR_LIGHTING.G_Outdoor_Sockets_On_In_Auto;
    ELSE
        L_Target_Level := 0;
        L_Target_Socket := FALSE;
    END_IF;

    GVL_OUTDOOR_LIGHTING.G_Outdoor_Light_Level[L_Zone] := L_Target_Level;
    GVL_OUTDOOR_LIGHTING.G_Outdoor_Socket_State[L_Zone] := L_Target_Socket;

    L_Light_Index := GVL_OUTDOOR_LIGHTING.G_Outdoor_Light_Zone_Index[L_Zone];
    IF (L_Light_Index >= 1) AND (L_Light_Index <= GVL_CONSTANTS.C_MAX_LIGHT_ZONES) THEN
        FOR L_Slot := 1 TO GVL_CONSTANTS.C_MAX_RULES DO
            IF NOT VIO_Rule_Actions[L_Slot].Active THEN
                VIO_Rule_Actions[L_Slot].Active := TRUE;
                VIO_Rule_Actions[L_Slot].Triggered := FALSE;
                VIO_Rule_Actions[L_Slot].Action_Type := E_Rule_Action_Type.ACTION_SET_LIGHTING_BASE;
                VIO_Rule_Actions[L_Slot].Target_ID := TO_BYTE(L_Light_Index);
                VIO_Rule_Actions[L_Slot].Value := TO_REAL(L_Target_Level);
                EXIT;
            END_IF;
        END_FOR;
    END_IF;

    L_Socket_Index := GVL_OUTDOOR_LIGHTING.G_Outdoor_Socket_Index[L_Zone];
    IF (L_Socket_Index >= 1) AND (L_Socket_Index <= GVL_CONSTANTS.C_MAX_SOCKETS) THEN
        FOR L_Slot := 1 TO GVL_CONSTANTS.C_MAX_RULES DO
            IF NOT VIO_Rule_Actions[L_Slot].Active THEN
                VIO_Rule_Actions[L_Slot].Active := TRUE;
                VIO_Rule_Actions[L_Slot].Triggered := FALSE;
                VIO_Rule_Actions[L_Slot].Action_Type := E_Rule_Action_Type.ACTION_SET_SOCKET;
                VIO_Rule_Actions[L_Slot].Target_ID := TO_BYTE(L_Socket_Index);
                IF L_Target_Socket THEN
                    VIO_Rule_Actions[L_Slot].Value := REAL#1.0;
                ELSE
                    VIO_Rule_Actions[L_Slot].Value := REAL#0.0;
                END_IF;
                EXIT;
            END_IF;
        END_FOR;
    END_IF;
END_FOR;

IF L_Party THEN
    GVL_OUTDOOR_LIGHTING.G_Outdoor_Status_Text := 'OUTDOOR PARTY';
ELSIF L_Security THEN
    GVL_OUTDOOR_LIGHTING.G_Outdoor_Status_Text := 'OUTDOOR SECURITY';
ELSIF L_Dark AND L_Economy THEN
    GVL_OUTDOOR_LIGHTING.G_Outdoor_Status_Text := 'OUTDOOR ECONOMY';
ELSIF L_Dark THEN
    GVL_OUTDOOR_LIGHTING.G_Outdoor_Status_Text := 'OUTDOOR AUTO';
ELSE
    GVL_OUTDOOR_LIGHTING.G_Outdoor_Status_Text := 'OUTDOOR DAY OFF';
END_IF;

// >>> BULK_SYNC_ANCHOR: FB_Outdoor_Lighting_Manager <<<
END_FUNCTION_BLOCK