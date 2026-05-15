FUNCTION_BLOCK FB_Distributed_Recovery_Lock_Runtime
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
END_VAR
VAR
    L_Lock : ST_Distributed_Recovery_Lock;
END_VAR

IF NOT VI_Enable THEN
    GVL_Distributed_Recovery_Lock.G_Runtime_Valid := FALSE;
    RETURN;
END_IF;

L_Lock := GVL_Distributed_Recovery_Lock.G_Recovery_Lock;

L_Lock.Runtime_System_Time_MS := VI_System_Time_MS;
L_Lock.Lock_Valid := TRUE;

// Cluster-exclusive recovery execution lock.
IF GVL_Distributed_Runtime.G_Split_Brain_Suspected
   OR GVL_Distributed_Projection_Ownership.G_Any_Ownership_Conflict
   OR GVL_Runtime_Sessions.G_Any_Stale_Session THEN

    L_Lock.Lock_Conflict := TRUE;
    L_Lock.Distributed_Execution_Allowed := FALSE;

    GVL_Distributed_Recovery_Lock.G_Recovery_Execution_Blocked := TRUE;
    GVL_Distributed_Recovery_Lock.G_Rollback_Execution_Blocked := TRUE;
    GVL_Distributed_Recovery_Lock.G_Reopen_Execution_Blocked := TRUE;

    L_Lock.Status_Code := 3;
    L_Lock.Status_Text :=
        'Distributed recovery execution locked';

ELSE

    L_Lock.Recovery_Lock_Active := TRUE;
    L_Lock.Distributed_Execution_Allowed := TRUE;

    GVL_Distributed_Recovery_Lock.G_Recovery_Execution_Blocked := FALSE;
    GVL_Distributed_Recovery_Lock.G_Rollback_Execution_Blocked := FALSE;
    GVL_Distributed_Recovery_Lock.G_Reopen_Execution_Blocked := FALSE;

    L_Lock.Status_Code := 0;
    L_Lock.Status_Text :=
        'Distributed recovery lock healthy';

END_IF;

GVL_Distributed_Recovery_Lock.G_Recovery_Lock := L_Lock;

GVL_Distributed_Recovery_Lock.G_Runtime_Valid := TRUE;
GVL_Distributed_Recovery_Lock.G_Last_Update_MS :=
    VI_System_Time_MS;

GVL_Distributed_Recovery_Lock.G_Status_Code :=
    L_Lock.Status_Code;

GVL_Distributed_Recovery_Lock.G_Status_Text :=
    L_Lock.Status_Text;

END_FUNCTION_BLOCK