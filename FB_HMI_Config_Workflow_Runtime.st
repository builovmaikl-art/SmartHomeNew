FUNCTION_BLOCK FB_HMI_Config_Workflow_Runtime
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
END_VAR
VAR
    L_State : ST_HMI_Config_Workflow_State;
END_VAR

IF NOT VI_Enable THEN
    GVL_HMI_Config_Workflow.G_Runtime_Valid := FALSE;
    RETURN;
END_IF;

// Preserve workflow memory from the previous scan. Validation is a state of the
// current draft and must remain visible until a new validation request changes it.
L_State := GVL_HMI_Config_Workflow.G_Workflow_State;

L_State.Runtime_Valid := TRUE;
L_State.Runtime_System_Time_MS := VI_System_Time_MS;

L_State.Editor_Open :=
    GVL_HMI_Config_Workflow.G_Open_Editor_Request;

L_State.Validation_Requested :=
    GVL_HMI_Config_Workflow.G_Validate_Request;

L_State.Activation_Requested :=
    GVL_HMI_Config_Workflow.G_Activate_Request;

L_State.Rollback_Requested :=
    GVL_HMI_Config_Workflow.G_Rollback_Request;

L_State.Reset_Default_Requested :=
    GVL_HMI_Config_Workflow.G_Reset_Default_Request;

L_State.Active_Version :=
    GVL_Water_Topology_Config.G_Active_Config_Version;

// Draft identity follows the generic staged config version. The staged change
// monitor increments it when any GVL_CONFIG_CONTROL.STG_* value changes.
L_State.Draft_Version :=
    GVL_CONFIG_CONTROL.G_Staged_Config_Version;

L_State.Last_Stable_Version :=
    GVL_Config_Activation.G_Last_Stable_Config_Version;

L_State.Topology_Activation_Required :=
    GVL_Config_Activation.G_Staged_Config_Version <> GVL_Water_Topology_Config.G_Active_Config_Version;

L_State.Topology_Validation_OK :=
    (NOT L_State.Topology_Activation_Required) OR GVL_Config_Activation.G_Activation_State.Staged_Config_Valid;

L_State.Quarantine_Visible :=
    GVL_Config_Activation.G_Config_Quarantine_Active;

L_State.Service_Mode_Required := TRUE;
L_State.Operator_Ack_Required := TRUE;
L_State.Activation_Allowed := FALSE;
L_State.Activation_Blocked := FALSE;
L_State.Rollback_Allowed := FALSE;
L_State.Reset_Default_Allowed := FALSE;

IF L_State.Validated_Draft_Version <> L_State.Draft_Version THEN
    L_State.Validation_OK := FALSE;
    L_State.Validation_Failed := FALSE;
    L_State.Draft_Dirty := TRUE;
END_IF;

IF L_State.Editor_Open THEN
    L_State.Edit_Session_Active := TRUE;
END_IF;

IF L_State.Validation_Requested THEN
    // HMI Validate launches the staged-config simulation gate. The simulation
    // manager consumes the request and publishes result/error for HMI and apply.
    GVL_CONFIG_SIMULATION.G_Simulation_Request := TRUE;
    GVL_CONFIG_SIMULATION.G_Simulation_Confirm := TRUE;
END_IF;

// Consume only a new simulation result. Sequence is used instead of timestamp so
// repeated simulation runs in the same millisecond are still detected.
IF (GVL_CONFIG_SIMULATION.G_Simulation_Result_Seq <> 0) AND
   (GVL_CONFIG_SIMULATION.G_Simulation_Result_Seq <> L_State.Validation_Result_Seq) THEN

    IF L_State.Topology_Validation_OK
       AND GVL_CONFIG_SIMULATION.G_Simulation_Result_OK THEN

        L_State.Validation_OK := TRUE;
        L_State.Validation_Failed := FALSE;
        L_State.Validated_Draft_Version := L_State.Draft_Version;
        L_State.Validation_Last_Run_MS := GVL_CONFIG_SIMULATION.G_Simulation_Last_Run_MS;
        L_State.Validation_Result_Seq := GVL_CONFIG_SIMULATION.G_Simulation_Result_Seq;
        L_State.Draft_Dirty := FALSE;

    ELSE

        L_State.Validation_OK := FALSE;
        L_State.Validation_Failed := TRUE;
        L_State.Validation_Last_Run_MS := GVL_CONFIG_SIMULATION.G_Simulation_Last_Run_MS;
        L_State.Validation_Result_Seq := GVL_CONFIG_SIMULATION.G_Simulation_Result_Seq;

    END_IF;

END_IF;

IF L_State.Activation_Requested THEN

    IF GVL_HMI_Config_Workflow.G_Service_Mode_Active
       AND GVL_HMI_Config_Workflow.G_Operator_Ack
       AND L_State.Validation_OK
       AND (L_State.Validated_Draft_Version = L_State.Draft_Version)
       AND GVL_CONFIG_SIMULATION.G_Simulation_Result_OK THEN

        L_State.Activation_Allowed := TRUE;
        IF L_State.Topology_Activation_Required THEN
            GVL_Config_Activation.G_Activation_Request := TRUE;
        END_IF;
        GVL_CONFIG_CONTROL.G_Apply_Request := TRUE;
        GVL_CONFIG_CONTROL.G_Apply_Confirm := TRUE;

    ELSE

        L_State.Activation_Blocked := TRUE;

    END_IF;

END_IF;

IF L_State.Rollback_Requested THEN

    IF GVL_HMI_Config_Workflow.G_Operator_Ack THEN

        L_State.Rollback_Allowed := TRUE;
        GVL_Config_Activation.G_Rollback_Request := TRUE;
        GVL_CONFIG_CONTROL.G_Rollback_Request := TRUE;
        GVL_CONFIG_CONTROL.G_Rollback_Confirm := TRUE;

    END_IF;

END_IF;

IF L_State.Reset_Default_Requested THEN

    IF GVL_HMI_Config_Workflow.G_Service_Mode_Active
       AND GVL_HMI_Config_Workflow.G_Operator_Ack THEN

        L_State.Reset_Default_Allowed := TRUE;
        GVL_CONFIG_CONTROL.G_Reset_Default_Request := TRUE;
        GVL_CONFIG_CONTROL.G_Reset_Default_Confirm := TRUE;

    END_IF;

END_IF;

IF L_State.Activation_Blocked THEN

    L_State.Status_Code := 2;
    L_State.Status_Text := 'HMI activation blocked';

ELSIF L_State.Validation_Failed THEN

    L_State.Status_Code := 1;
    L_State.Status_Text := 'HMI validation failed';

ELSIF L_State.Validation_Requested THEN

    L_State.Status_Code := 0;
    L_State.Status_Text := 'HMI config validation requested';

ELSIF L_State.Activation_Allowed THEN

    L_State.Status_Code := 0;
    L_State.Status_Text := 'HMI config activation requested';

ELSIF L_State.Rollback_Allowed THEN

    L_State.Status_Code := 0;
    L_State.Status_Text := 'HMI config rollback requested';

ELSIF L_State.Reset_Default_Allowed THEN

    L_State.Status_Code := 0;
    L_State.Status_Text := 'HMI config reset default requested';

ELSIF L_State.Draft_Dirty THEN

    L_State.Status_Code := 1;
    L_State.Status_Text := 'HMI draft changed - validation required';

ELSIF L_State.Validation_OK THEN

    L_State.Status_Code := 0;
    L_State.Status_Text := 'HMI validation passed';

ELSE

    L_State.Status_Code := 0;
    L_State.Status_Text := 'HMI config workflow healthy';

END_IF;

GVL_HMI_Config_Workflow.G_Workflow_State := L_State;

GVL_HMI_Config_Workflow.G_Runtime_Valid := TRUE;
GVL_HMI_Config_Workflow.G_Last_Update_MS := VI_System_Time_MS;
GVL_HMI_Config_Workflow.G_Status_Code := L_State.Status_Code;
GVL_HMI_Config_Workflow.G_Status_Text := L_State.Status_Text;

IF GVL_HMI_Config_Workflow.G_Validate_Request THEN
    GVL_HMI_Config_Workflow.G_Validate_Request := FALSE;
END_IF;

IF GVL_HMI_Config_Workflow.G_Activate_Request THEN
    GVL_HMI_Config_Workflow.G_Activate_Request := FALSE;
END_IF;

IF GVL_HMI_Config_Workflow.G_Rollback_Request THEN
    GVL_HMI_Config_Workflow.G_Rollback_Request := FALSE;
END_IF;

IF GVL_HMI_Config_Workflow.G_Reset_Default_Request THEN
    GVL_HMI_Config_Workflow.G_Reset_Default_Request := FALSE;
END_IF;

END_FUNCTION_BLOCK