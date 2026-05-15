FUNCTION_BLOCK FB_Cluster_Safety_Barrier_Runtime
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
END_VAR
VAR
    L_Block_Execution : BOOL;
    L_Status_Code : UINT;
    L_Status_Text : STRING(160);
END_VAR

IF NOT VI_Enable THEN
    GVL_Cluster_Safety_Barrier.G_Runtime_Valid := FALSE;
    RETURN;
END_IF;

L_Block_Execution := FALSE;
L_Status_Code := 0;
L_Status_Text := 'Cluster safety barrier healthy';

GVL_Cluster_Safety_Barrier.G_Remote_Authority_Degraded := FALSE;
GVL_Cluster_Safety_Barrier.G_Runtime_Bus_Degraded := FALSE;
GVL_Cluster_Safety_Barrier.G_Projection_Ownership_Invalid := FALSE;
GVL_Cluster_Safety_Barrier.G_Recovery_Lock_Active := FALSE;
GVL_Cluster_Safety_Barrier.G_Deployment_Invalid := FALSE;
GVL_Cluster_Safety_Barrier.G_Authority_Downgraded := FALSE;
GVL_Cluster_Safety_Barrier.G_Orchestration_Restricted := FALSE;

// Remote authority staleness barrier.
IF GVL_Distributed_Runtime.G_Any_Remote_Node_Offline
   OR GVL_Distributed_Runtime.G_Split_Brain_Suspected THEN

    L_Block_Execution := TRUE;
    L_Status_Code := 10;
    L_Status_Text :=
        'Cluster authority state degraded';

    GVL_Cluster_Safety_Barrier.G_Remote_Authority_Degraded := TRUE;

END_IF;

// Runtime bus integrity barrier.
IF GVL_Runtime_Bus.G_Any_Replication_Rejected
   OR NOT GVL_Runtime_Bus.G_TX_Healthy
   OR NOT GVL_Runtime_Bus.G_RX_Healthy THEN

    L_Block_Execution := TRUE;
    L_Status_Code := 11;
    L_Status_Text :=
        'Runtime bus integrity degraded';

    GVL_Cluster_Safety_Barrier.G_Runtime_Bus_Degraded := TRUE;

END_IF;

// Projection ownership barrier.
IF GVL_Distributed_Projection_Ownership.G_Any_Ownership_Conflict
   OR GVL_Distributed_Projection_Ownership.G_Any_Ownership_Stale THEN

    L_Block_Execution := TRUE;
    L_Status_Code := 12;
    L_Status_Text :=
        'Distributed projection ownership invalid';

    GVL_Cluster_Safety_Barrier.G_Projection_Ownership_Invalid := TRUE;

END_IF;

// Recovery lock barrier.
IF GVL_Distributed_Recovery_Lock.G_Recovery_Execution_Blocked
   OR GVL_Distributed_Recovery_Lock.G_Rollback_Execution_Blocked
   OR GVL_Distributed_Recovery_Lock.G_Reopen_Execution_Blocked THEN

    L_Block_Execution := TRUE;
    L_Status_Code := 13;
    L_Status_Text :=
        'Distributed recovery execution blocked';

    GVL_Cluster_Safety_Barrier.G_Recovery_Lock_Active := TRUE;

END_IF;

// Discovery/deployment barrier.
IF GVL_Runtime_Discovery.G_Any_Discovery_Rejected
   OR GVL_Runtime_Discovery.G_Any_Node_Quarantined THEN

    L_Block_Execution := TRUE;
    L_Status_Code := 14;
    L_Status_Text :=
        'Runtime deployment/discovery invalid';

    GVL_Cluster_Safety_Barrier.G_Deployment_Invalid := TRUE;

END_IF;

// Cluster escalation semantics.
IF L_Block_Execution THEN

    GVL_Distributed_Authority.G_Authority_State.Authority_Observer_Only := TRUE;
    GVL_Distributed_Authority.G_Authority_State.Authority_Master_Elected := FALSE;

    GVL_Distributed_Orchestration.G_Distributed_Projection_Healthy := FALSE;

    GVL_Cluster_Safety_Barrier.G_Authority_Downgraded := TRUE;
    GVL_Cluster_Safety_Barrier.G_Orchestration_Restricted := TRUE;

END_IF;

GVL_Cluster_Safety_Barrier.G_Cluster_Execution_Blocked :=
    L_Block_Execution;

GVL_Cluster_Safety_Barrier.G_Runtime_Valid := TRUE;
GVL_Cluster_Safety_Barrier.G_Last_Update_MS := VI_System_Time_MS;
GVL_Cluster_Safety_Barrier.G_Status_Code := L_Status_Code;
GVL_Cluster_Safety_Barrier.G_Status_Text := L_Status_Text;

END_FUNCTION_BLOCK