FUNCTION_BLOCK FB_Distributed_Orchestration_Runtime
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
END_VAR
VAR
    L_State : ST_Distributed_Orchestration_State;
END_VAR

IF NOT VI_Enable THEN
    GVL_Distributed_Orchestration.G_Runtime_Valid := FALSE;
    RETURN;
END_IF;

L_State := (Runtime_Valid := TRUE);
L_State.Runtime_System_Time_MS := VI_System_Time_MS;

L_State.Orchestration_Sequence_Id :=
    GVL_Distributed_Orchestration.G_Last_Distributed_Sequence_Id + 1;

L_State.Distributed_Execution_Active := TRUE;

L_State.Cross_Node_Isolation_Required :=
    GVL_Distributed_Orchestration.G_Cross_Node_Isolation_Active;

L_State.Cross_Node_Recovery_Required :=
    GVL_Distributed_Orchestration.G_Cross_Node_Recovery_Active;

L_State.Cross_Node_Rollback_Required :=
    GVL_Distributed_Orchestration.G_Cross_Node_Rollback_Active;

L_State.Distributed_Scheduler_Healthy :=
    GVL_Runtime_Bus.G_TX_Healthy
    AND GVL_Distributed_Runtime.G_Distributed_Authority_Healthy;

L_State.Distributed_Timing_Window_Valid :=
    GVL_Distributed_Authority.G_Distributed_Safety_Barrier_OK;

IF L_State.Distributed_Scheduler_Healthy
   AND L_State.Distributed_Timing_Window_Valid THEN

    L_State.Distributed_Projection_Granted := TRUE;
    L_State.Distributed_Recovery_Allowed := TRUE;
    L_State.Distributed_Rollback_Allowed := TRUE;

    L_State.Status_Code := 0;
    L_State.Status_Text :=
        'Distributed orchestration runtime healthy';

ELSE

    L_State.Distributed_Projection_Blocked := TRUE;
    L_State.Distributed_Conflict_Detected := TRUE;

    L_State.Status_Code := 2;
    L_State.Status_Text :=
        'Distributed orchestration blocked';

END_IF;

IF GVL_Distributed_Runtime.G_Split_Brain_Suspected THEN

    L_State.Distributed_Split_Execution_Suspected := TRUE;

    L_State.Distributed_Projection_Blocked := TRUE;

    L_State.Status_Code := 3;
    L_State.Status_Text :=
        'Distributed split execution suspected';

END_IF;

GVL_Distributed_Orchestration.G_Orchestration_State :=
    L_State;

GVL_Distributed_Orchestration.G_Last_Distributed_Sequence_Id :=
    L_State.Orchestration_Sequence_Id;

GVL_Distributed_Orchestration.G_Distributed_Projection_Healthy :=
    L_State.Distributed_Projection_Granted;

GVL_Distributed_Orchestration.G_Distributed_Scheduler_Healthy :=
    L_State.Distributed_Scheduler_Healthy;

GVL_Distributed_Orchestration.G_Runtime_Valid := TRUE;
GVL_Distributed_Orchestration.G_Last_Update_MS := VI_System_Time_MS;
GVL_Distributed_Orchestration.G_Status_Code := L_State.Status_Code;
GVL_Distributed_Orchestration.G_Status_Text := L_State.Status_Text;

END_FUNCTION_BLOCK