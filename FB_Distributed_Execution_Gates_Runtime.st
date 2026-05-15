FUNCTION_BLOCK FB_Distributed_Execution_Gates_Runtime
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
END_VAR
VAR
    L_Allow : BOOL;
END_VAR

IF NOT VI_Enable THEN
    GVL_Distributed_Execution_Gates.G_Runtime_Valid := FALSE;
    RETURN;
END_IF;

L_Allow :=
    NOT GVL_Cluster_Safety_Barrier.G_Cluster_Execution_Blocked
    AND GVL_Distributed_Authority.G_Authority_State.Authority_Master_Elected
    AND NOT GVL_Distributed_Runtime.G_Split_Brain_Suspected
    AND NOT GVL_Distributed_Projection_Ownership.G_Any_Ownership_Conflict
    AND NOT GVL_Runtime_Sessions.G_Any_Stale_Session;

GVL_Distributed_Execution_Gates.G_Can_Replicate :=
    L_Allow
    AND GVL_Runtime_Bus.G_TX_Healthy
    AND GVL_Runtime_Bus.G_RX_Healthy;

GVL_Distributed_Execution_Gates.G_Can_Execute :=
    L_Allow;

GVL_Distributed_Execution_Gates.G_Can_Orchestrate :=
    L_Allow
    AND GVL_Distributed_Orchestration.G_Distributed_Scheduler_Healthy;

GVL_Distributed_Execution_Gates.G_Can_Recover :=
    L_Allow
    AND NOT GVL_Distributed_Recovery_Lock.G_Recovery_Execution_Blocked;

GVL_Distributed_Execution_Gates.G_Can_Rollback :=
    L_Allow
    AND NOT GVL_Distributed_Recovery_Lock.G_Rollback_Execution_Blocked;

GVL_Distributed_Execution_Gates.G_Can_Own_Projection :=
    L_Allow
    AND NOT GVL_Distributed_Projection_Ownership.G_Any_Projection_Blocked;

GVL_Distributed_Execution_Gates.G_Runtime_Valid := TRUE;
GVL_Distributed_Execution_Gates.G_Last_Update_MS :=
    VI_System_Time_MS;

IF L_Allow THEN
    GVL_Distributed_Execution_Gates.G_Status_Code := 0;
    GVL_Distributed_Execution_Gates.G_Status_Text :=
        'Distributed execution gates open';
ELSE
    GVL_Distributed_Execution_Gates.G_Status_Code := 1;
    GVL_Distributed_Execution_Gates.G_Status_Text :=
        'Distributed execution gates restricted';
END_IF;

END_FUNCTION_BLOCK