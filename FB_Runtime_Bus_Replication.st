FUNCTION_BLOCK FB_Runtime_Bus_Replication
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
END_VAR
VAR
    L_Frame : ST_Runtime_Bus_Frame;
    L_TX_Index : UINT;
END_VAR

IF NOT VI_Enable THEN
    GVL_Runtime_Bus.G_Runtime_Valid := FALSE;
    RETURN;
END_IF;

// Deterministic runtime replication frame publication.
L_TX_Index := GVL_Runtime_Bus.G_Last_Sequence_Id + 1;

IF L_TX_Index > 128 THEN
    L_TX_Index := 1;
END_IF;

L_Frame := (Frame_Valid := TRUE);

L_Frame.Frame_Time_MS := VI_System_Time_MS;
L_Frame.Frame_Id := GVL_Runtime_Bus.G_Last_Frame_Id + 1;

L_Frame.Source_Controller_Id :=
    GVL_Distributed_Runtime.G_Local_Node_State.Controller_Id;

L_Frame.Source_Runtime_Node_Id :=
    GVL_Distributed_Runtime.G_Local_Node_State.Runtime_Node_Id;

L_Frame.Frame_Sequence_Id :=
    GVL_Runtime_Bus.G_Last_Sequence_Id + 1;

L_Frame.Frame_Ack_Required := TRUE;

// Replicated semantic domains.
L_Frame.Authority_State_Frame := TRUE;
L_Frame.Recovery_State_Frame := TRUE;
L_Frame.Quarantine_State_Frame := TRUE;
L_Frame.Topology_State_Frame := TRUE;
L_Frame.Binding_State_Frame := TRUE;
L_Frame.Predictive_State_Frame := TRUE;

// Deterministic replication safety.
IF GVL_Distributed_Authority.G_Distributed_Safety_Barrier_OK
   AND NOT GVL_Distributed_Runtime.G_Split_Brain_Suspected THEN

    L_Frame.Replication_Consistent := TRUE;

    L_Frame.Status_Code := 0;
    L_Frame.Status_Text :=
        'Deterministic replication frame accepted';

ELSE

    L_Frame.Replication_Rejected := TRUE;

    L_Frame.Status_Code := 2;
    L_Frame.Status_Text :=
        'Deterministic replication frame rejected';

END_IF;

GVL_Runtime_Bus.G_TX_Frames[L_TX_Index] := L_Frame;

GVL_Runtime_Bus.G_Last_Frame_Id :=
    L_Frame.Frame_Id;

GVL_Runtime_Bus.G_Last_Sequence_Id :=
    L_Frame.Frame_Sequence_Id;

GVL_Runtime_Bus.G_TX_Healthy :=
    L_Frame.Replication_Consistent;

GVL_Runtime_Bus.G_RX_Healthy := TRUE;

GVL_Runtime_Bus.G_Any_Replication_Rejected :=
    L_Frame.Replication_Rejected;

GVL_Runtime_Bus.G_Runtime_Valid := TRUE;
GVL_Runtime_Bus.G_Last_Update_MS := VI_System_Time_MS;

IF L_Frame.Replication_Rejected THEN
    GVL_Runtime_Bus.G_Status_Code := 2;
    GVL_Runtime_Bus.G_Status_Text :=
        'Runtime bus replication rejected';
ELSE
    GVL_Runtime_Bus.G_Status_Code := 0;
    GVL_Runtime_Bus.G_Status_Text :=
        'Runtime bus replication healthy';
END_IF;

END_FUNCTION_BLOCK