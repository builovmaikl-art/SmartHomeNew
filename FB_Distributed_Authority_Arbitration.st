FUNCTION_BLOCK FB_Distributed_Authority_Arbitration
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
END_VAR
VAR
    L_State : ST_Distributed_Authority_State;
    L_Lease_Expired : BOOL;
END_VAR

IF NOT VI_Enable THEN
    GVL_Distributed_Authority.G_Runtime_Valid := FALSE;
    RETURN;
END_IF;

L_State := (Runtime_Valid := TRUE);
L_State.Runtime_System_Time_MS := VI_System_Time_MS;

L_State.Controller_Id :=
    GVL_Distributed_Runtime.G_Local_Node_State.Controller_Id;

L_State.Runtime_Node_Id :=
    GVL_Distributed_Runtime.G_Local_Node_State.Runtime_Node_Id;

L_State.Authority_Domain_Id :=
    GVL_Distributed_Runtime.G_Local_Node_State.Authority_Domain_Id;

L_State.Authority_Election_Active := TRUE;

L_Lease_Expired :=
    (VI_System_Time_MS - GVL_Distributed_Authority.G_Authority_Lease_Start_MS)
    > GVL_Distributed_Authority.G_Authority_Lease_Duration_MS;

L_State.Authority_Lease_Expired := L_Lease_Expired;
L_State.Authority_Lease_Valid := NOT L_Lease_Expired;

L_State.Replication_Consensus_Healthy :=
    GVL_Distributed_Runtime.G_Distributed_Replication_Healthy;

L_State.Replication_Consensus_Stale :=
    NOT GVL_Distributed_Runtime.G_Distributed_Replication_Healthy;

// Distributed pre-authority safety barrier.
L_State.Distributed_Safety_Barrier_OK :=
    GVL_Runtime_Restart_Continuity.G_Runtime_Valid
    AND NOT GVL_Config_Activation.G_Config_Quarantine_Active
    AND NOT GVL_Distributed_Runtime.G_Split_Brain_Suspected
    AND GVL_IO_Binding_Runtime.G_Runtime_Valid;

IF NOT L_State.Distributed_Safety_Barrier_OK THEN

    L_State.Split_Brain_Blocked := TRUE;
    L_State.Authority_Observer_Only := TRUE;

    L_State.Status_Code := 3;
    L_State.Status_Text :=
        'Distributed authority blocked by safety barrier';

ELSIF L_State.Replication_Consensus_Healthy
   AND NOT L_Lease_Expired THEN

    L_State.Authority_Master_Elected := TRUE;

    L_State.Recovery_Authority_Allowed := TRUE;
    L_State.Rollback_Authority_Allowed := TRUE;
    L_State.Quarantine_Authority_Allowed := TRUE;

    L_State.Status_Code := 1;
    L_State.Status_Text :=
        'Distributed master authority active';

ELSE

    L_State.Authority_Backup_Elected := TRUE;

    L_State.Status_Code := 2;
    L_State.Status_Text :=
        'Distributed backup authority active';

END_IF;

GVL_Distributed_Authority.G_Authority_State := L_State;

GVL_Distributed_Authority.G_Split_Brain_Blocked :=
    L_State.Split_Brain_Blocked;

GVL_Distributed_Authority.G_Distributed_Safety_Barrier_OK :=
    L_State.Distributed_Safety_Barrier_OK;

GVL_Distributed_Authority.G_Runtime_Valid := TRUE;
GVL_Distributed_Authority.G_Last_Update_MS := VI_System_Time_MS;
GVL_Distributed_Authority.G_Status_Code := L_State.Status_Code;
GVL_Distributed_Authority.G_Status_Text := L_State.Status_Text;

END_FUNCTION_BLOCK