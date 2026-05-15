FUNCTION_BLOCK FB_Cluster_Runtime_FSM
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
END_VAR

IF NOT VI_Enable THEN
    GVL_Cluster_Runtime_FSM.G_Runtime_Valid := FALSE;
    RETURN;
END_IF;

// Reset runtime states.
GVL_Cluster_Runtime_FSM.G_State_Startup := FALSE;
GVL_Cluster_Runtime_FSM.G_State_Discovery := FALSE;
GVL_Cluster_Runtime_FSM.G_State_Synchronization := FALSE;
GVL_Cluster_Runtime_FSM.G_State_Operational := FALSE;
GVL_Cluster_Runtime_FSM.G_State_Degraded := FALSE;
GVL_Cluster_Runtime_FSM.G_State_Observer_Only := FALSE;
GVL_Cluster_Runtime_FSM.G_State_Recovery_Lock := FALSE;
GVL_Cluster_Runtime_FSM.G_State_Quarantine := FALSE;

// Startup state.
IF NOT GVL_Distributed_Runtime.G_Runtime_Valid THEN

    GVL_Cluster_Runtime_FSM.G_State_Startup := TRUE;

    GVL_Cluster_Runtime_FSM.G_Status_Code := 1;
    GVL_Cluster_Runtime_FSM.G_Status_Text :=
        'Cluster runtime startup';

ELSIF GVL_Runtime_Discovery.G_Runtime_Valid
   AND NOT GVL_Runtime_Discovery.G_Any_Discovery_Rejected THEN

    GVL_Cluster_Runtime_FSM.G_State_Discovery := TRUE;

    GVL_Cluster_Runtime_FSM.G_Status_Code := 2;
    GVL_Cluster_Runtime_FSM.G_Status_Text :=
        'Cluster runtime discovery';

END_IF;

// Synchronization state.
IF GVL_Runtime_Bus.G_TX_Healthy
   AND GVL_Runtime_Bus.G_RX_Healthy THEN

    GVL_Cluster_Runtime_FSM.G_State_Synchronization := TRUE;

END_IF;

// Operational state.
IF GVL_Distributed_Execution_Gates.G_Can_Execute
   AND GVL_Distributed_Execution_Gates.G_Can_Orchestrate THEN

    GVL_Cluster_Runtime_FSM.G_State_Operational := TRUE;

    GVL_Cluster_Runtime_FSM.G_Status_Code := 0;
    GVL_Cluster_Runtime_FSM.G_Status_Text :=
        'Cluster runtime operational';

END_IF;

// Degraded state.
IF GVL_Cluster_Safety_Barrier.G_Cluster_Execution_Blocked THEN

    GVL_Cluster_Runtime_FSM.G_State_Degraded := TRUE;

    GVL_Cluster_Runtime_FSM.G_Status_Code := 10;
    GVL_Cluster_Runtime_FSM.G_Status_Text :=
        'Cluster runtime degraded';

END_IF;

// Observer-only state.
IF GVL_Distributed_Authority.G_Authority_State.Authority_Observer_Only THEN

    GVL_Cluster_Runtime_FSM.G_State_Observer_Only := TRUE;

    GVL_Cluster_Runtime_FSM.G_Status_Code := 11;
    GVL_Cluster_Runtime_FSM.G_Status_Text :=
        'Cluster runtime observer-only';

END_IF;

// Recovery lock state.
IF GVL_Distributed_Recovery_Lock.G_Recovery_Execution_Blocked THEN

    GVL_Cluster_Runtime_FSM.G_State_Recovery_Lock := TRUE;

    GVL_Cluster_Runtime_FSM.G_Status_Code := 12;
    GVL_Cluster_Runtime_FSM.G_Status_Text :=
        'Cluster runtime recovery-locked';

END_IF;

// Quarantine state.
IF GVL_Runtime_Discovery.G_Any_Node_Quarantined THEN

    GVL_Cluster_Runtime_FSM.G_State_Quarantine := TRUE;

    GVL_Cluster_Runtime_FSM.G_Status_Code := 13;
    GVL_Cluster_Runtime_FSM.G_Status_Text :=
        'Cluster runtime quarantined';

END_IF;

GVL_Cluster_Runtime_FSM.G_Runtime_Valid := TRUE;
GVL_Cluster_Runtime_FSM.G_Last_Update_MS := VI_System_Time_MS;

END_FUNCTION_BLOCK