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

L_State := (Runtime_Valid := TRUE);
L_State.Runtime_System_Time_MS := VI_System_Time_MS;

L_State.Editor_Open :=
    GVL_HMI_Config_Workflow.G_Open_Editor_Request;

L_State.Validation_Requested :=
    GVL_HMI_Config_Workflow.G_Validate_Request;

L_State.Activation_Requested :=
    GVL_HMI_Config_Workflow.G_Activate_Request;

L_State.Rollback_Requested :=
    GVL_HMI_Config_Workflow.G_Rollback_Request;

L_State.Active_Version :=
    GVL_Water_Topology_Config.G_Active_Config_Version;

L_State.Draft_Version :=
    GVL_Config_Activation.G_Staged_Config_Version;

L_State.Last_Stable_Version :=
    GVL_Config_Activation.G_Last_Stable_Config_Version;

L_State.Quarantine_Visible :=
    GVL_Config_Activation.G_Config_Quarantine_Active;

L_State.Service_Mode_Required := TRUE;
L_State.Operator_Ack_Required := TRUE;

IF L_State.Editor_Open THEN
    L_State.Edit_Session_Active := TRUE;
END_IF;

IF L_State.Validation_Requested THEN

    IF GVL_Config_Activation.G_Activation_State.Staged_Config_Valid THEN

        L_State.Validation_OK := TRUE;

    ELSE

        L_State.Validation_Failed := TRUE;

    END_IF;

END_IF;

IF L_State.Activation_Requested THEN

    IF GVL_HMI_Config_Workflow.G_Service_Mode_Active
       AND GVL_HMI_Config_Workflow.G_Operator_Ack
       AND L_State.Validation_OK THEN

        L_State.Activation_Allowed := TRUE;
        GVL_Config_Activation.G_Activation_Request := TRUE;

    ELSE

        L_State.Activation_Blocked := TRUE;

    END_IF;

END_IF;

IF L_State.Rollback_Requested THEN

    IF GVL_HMI_Config_Workflow.G_Operator_Ack THEN

        L_State.Rollback_Allowed := TRUE;
        GVL_Config_Activation.G_Rollback_Request := TRUE;

    END_IF;

END_IF;

IF L_State.Activation_Blocked THEN

    L_State.Status_Code := 2;
    L_State.Status_Text := 'HMI activation blocked';

ELSIF L_State.Validation_Failed THEN

    L_State.Status_Code := 1;
    L_State.Status_Text := 'HMI validation failed';

ELSE

    L_State.Status_Code := 0;
    L_State.Status_Text := 'HMI config workflow healthy';

END_IF;

GVL_HMI_Config_Workflow.G_Workflow_State := L_State;

GVL_HMI_Config_Workflow.G_Runtime_Valid := TRUE;
GVL_HMI_Config_Workflow.G_Last_Update_MS := VI_System_Time_MS;
GVL_HMI_Config_Workflow.G_Status_Code := L_State.Status_Code;
GVL_HMI_Config_Workflow.G_Status_Text := L_State.Status_Text;

END_FUNCTION_BLOCK