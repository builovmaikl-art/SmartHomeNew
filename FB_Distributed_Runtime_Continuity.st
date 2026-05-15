FUNCTION_BLOCK FB_Distributed_Runtime_Continuity
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
END_VAR
VAR
    L_i : INT;
    L_Node : ST_Distributed_Runtime_Node_State;

    L_Any_Offline : BOOL;
    L_Any_Degraded : BOOL;
    L_Split_Brain : BOOL;
END_VAR

IF NOT VI_Enable THEN
    GVL_Distributed_Runtime.G_Runtime_Valid := FALSE;
    RETURN;
END_IF;

// Local node authoritative runtime state.
GVL_Distributed_Runtime.G_Local_Node_State.Runtime_Valid := TRUE;
GVL_Distributed_Runtime.G_Local_Node_State.Runtime_System_Time_MS :=
    VI_System_Time_MS;

GVL_Distributed_Runtime.G_Local_Node_State.Node_Online := TRUE;

GVL_Distributed_Runtime.G_Local_Node_State.Restart_Continuity_Valid :=
    GVL_Runtime_Restart_Continuity.G_Runtime_Valid;

GVL_Distributed_Runtime.G_Local_Node_State.Quarantine_State_Replicated :=
    NOT GVL_Config_Activation.G_Config_Quarantine_Active;

GVL_Distributed_Runtime.G_Local_Node_State.Recovery_State_Replicated :=
    GVL_Water_Recovery_Runtime.G_Runtime_Valid;

GVL_Distributed_Runtime.G_Local_Node_State.Authority_Allowed :=
    NOT GVL_COMMAND_VERIFY.PreOutput_Block_IO;

GVL_Distributed_Runtime.G_Local_Node_State.Replication_Healthy := TRUE;

FOR L_i := 1 TO 8 DO

    L_Node := GVL_Distributed_Runtime.G_Remote_Node_State[L_i];

    IF L_Node.Runtime_Valid THEN

        IF NOT L_Node.Node_Online THEN
            L_Any_Offline := TRUE;
        END_IF;

        IF L_Node.Node_Degraded
           OR L_Node.Node_Quarantined THEN

            L_Any_Degraded := TRUE;

        END_IF;

        IF L_Node.Authority_Master
           AND GVL_Distributed_Runtime.G_Local_Node_State.Authority_Master THEN

            L_Split_Brain := TRUE;

        END_IF;

    END_IF;

END_FOR;

GVL_Distributed_Runtime.G_Any_Remote_Node_Offline :=
    L_Any_Offline;

GVL_Distributed_Runtime.G_Any_Remote_Node_Degraded :=
    L_Any_Degraded;

GVL_Distributed_Runtime.G_Split_Brain_Suspected :=
    L_Split_Brain;

GVL_Distributed_Runtime.G_Distributed_Replication_Healthy :=
    NOT L_Any_Offline;

GVL_Distributed_Runtime.G_Distributed_Authority_Healthy :=
    NOT L_Split_Brain;

GVL_Distributed_Runtime.G_Runtime_Valid := TRUE;
GVL_Distributed_Runtime.G_Last_Update_MS := VI_System_Time_MS;

IF L_Split_Brain THEN
    GVL_Distributed_Runtime.G_Status_Code := 3;
    GVL_Distributed_Runtime.G_Status_Text :=
        'Distributed split-brain suspected';
ELSIF L_Any_Degraded THEN
    GVL_Distributed_Runtime.G_Status_Code := 2;
    GVL_Distributed_Runtime.G_Status_Text :=
        'Distributed degraded node detected';
ELSIF L_Any_Offline THEN
    GVL_Distributed_Runtime.G_Status_Code := 1;
    GVL_Distributed_Runtime.G_Status_Text :=
        'Distributed offline node detected';
ELSE
    GVL_Distributed_Runtime.G_Status_Code := 0;
    GVL_Distributed_Runtime.G_Status_Text :=
        'Distributed runtime continuity healthy';
END_IF;

END_FUNCTION_BLOCK