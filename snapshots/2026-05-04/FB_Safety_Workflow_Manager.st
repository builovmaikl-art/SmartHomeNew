FUNCTION_BLOCK FB_Safety_Workflow_Manager
VAR_INPUT
    VI_System_Time_MS : UDINT;
    VI_Water_Selective_Recover : BOOL;
    VI_Gas_Selective_Recover : BOOL;
    VI_Water_Valve_Test_Open : BOOL;
    VI_Water_Valve_Test_Close : BOOL;
    VI_Water_Valve_Test_Confirm : BOOL;
    VI_Gas_Valve_Test_Open : BOOL;
    VI_Gas_Valve_Test_Close : BOOL;
    VI_Gas_Valve_Test_Confirm : BOOL;
END_VAR
VAR_OUTPUT
    VO_Water_Selective_Recover_Edge : BOOL;
    VO_Gas_Selective_Recover_Edge : BOOL;
    VO_Water_Valve_Test_Open_Edge : BOOL;
    VO_Water_Valve_Test_Close_Edge : BOOL;
    VO_Water_Valve_Test_Confirm_Edge : BOOL;
    VO_Gas_Valve_Test_Open_Edge : BOOL;
    VO_Gas_Valve_Test_Close_Edge : BOOL;
    VO_Gas_Valve_Test_Confirm_Edge : BOOL;
    VO_Water_Test_Active : BOOL;
    VO_Gas_Test_Active : BOOL;
    VO_Water_Test_Timeout_Close_Required : BOOL;
    VO_Gas_Test_Timeout_Close_Required : BOOL;
END_VAR
VAR
    L_CMD_Water_Selective_Recover_Prev : BOOL;
    L_CMD_Gas_Selective_Recover_Prev : BOOL;
    L_CMD_Water_Valve_Test_Open_Prev : BOOL;
    L_CMD_Water_Valve_Test_Close_Prev : BOOL;
    L_CMD_Water_Valve_Test_Confirm_Prev : BOOL;
    L_CMD_Gas_Valve_Test_Open_Prev : BOOL;
    L_CMD_Gas_Valve_Test_Close_Prev : BOOL;
    L_CMD_Gas_Valve_Test_Confirm_Prev : BOOL;
    L_Water_Test_Active : BOOL;
    L_Water_Test_Deadline : UDINT;
    L_Gas_Test_Active : BOOL;
    L_Gas_Test_Deadline : UDINT;
END_VAR

VO_Water_Test_Timeout_Close_Required := FALSE;
VO_Gas_Test_Timeout_Close_Required := FALSE;

VO_Water_Selective_Recover_Edge := VI_Water_Selective_Recover AND NOT L_CMD_Water_Selective_Recover_Prev;
VO_Gas_Selective_Recover_Edge := VI_Gas_Selective_Recover AND NOT L_CMD_Gas_Selective_Recover_Prev;
VO_Water_Valve_Test_Open_Edge := VI_Water_Valve_Test_Open AND NOT L_CMD_Water_Valve_Test_Open_Prev;
VO_Water_Valve_Test_Close_Edge := VI_Water_Valve_Test_Close AND NOT L_CMD_Water_Valve_Test_Close_Prev;
VO_Water_Valve_Test_Confirm_Edge := VI_Water_Valve_Test_Confirm AND NOT L_CMD_Water_Valve_Test_Confirm_Prev;
VO_Gas_Valve_Test_Open_Edge := VI_Gas_Valve_Test_Open AND NOT L_CMD_Gas_Valve_Test_Open_Prev;
VO_Gas_Valve_Test_Close_Edge := VI_Gas_Valve_Test_Close AND NOT L_CMD_Gas_Valve_Test_Close_Prev;
VO_Gas_Valve_Test_Confirm_Edge := VI_Gas_Valve_Test_Confirm AND NOT L_CMD_Gas_Valve_Test_Confirm_Prev;

L_CMD_Water_Selective_Recover_Prev := VI_Water_Selective_Recover;
L_CMD_Gas_Selective_Recover_Prev := VI_Gas_Selective_Recover;
L_CMD_Water_Valve_Test_Open_Prev := VI_Water_Valve_Test_Open;
L_CMD_Water_Valve_Test_Close_Prev := VI_Water_Valve_Test_Close;
L_CMD_Water_Valve_Test_Confirm_Prev := VI_Water_Valve_Test_Confirm;
L_CMD_Gas_Valve_Test_Open_Prev := VI_Gas_Valve_Test_Open;
L_CMD_Gas_Valve_Test_Close_Prev := VI_Gas_Valve_Test_Close;
L_CMD_Gas_Valve_Test_Confirm_Prev := VI_Gas_Valve_Test_Confirm;

IF VO_Water_Valve_Test_Open_Edge THEN
    L_Water_Test_Active := TRUE;
    L_Water_Test_Deadline := VI_System_Time_MS + 60000;
END_IF;

IF L_Water_Test_Active THEN
    IF VI_System_Time_MS >= L_Water_Test_Deadline THEN
        L_Water_Test_Active := FALSE;
        VO_Water_Test_Timeout_Close_Required := TRUE;
    END_IF;
END_IF;

IF VO_Gas_Valve_Test_Open_Edge THEN
    L_Gas_Test_Active := TRUE;
    L_Gas_Test_Deadline := VI_System_Time_MS + 60000;
END_IF;

IF L_Gas_Test_Active THEN
    IF VI_System_Time_MS >= L_Gas_Test_Deadline THEN
        L_Gas_Test_Active := FALSE;
        VO_Gas_Test_Timeout_Close_Required := TRUE;
    END_IF;
END_IF;

VO_Water_Test_Active := L_Water_Test_Active;
VO_Gas_Test_Active := L_Gas_Test_Active;
END_FUNCTION_BLOCK
