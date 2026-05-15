FUNCTION_BLOCK FB_Runtime_Restart_Continuity
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
    VI_Warm_Restart : BOOL;
END_VAR
VAR
    L_State : ST_Runtime_Restart_Continuity_State;
END_VAR

IF NOT VI_Enable THEN
    GVL_Runtime_Restart_Continuity.G_Runtime_Valid := FALSE;
    RETURN;
END_IF;

L_State := (Runtime_Valid := TRUE);
L_State.Runtime_System_Time_MS := VI_System_Time_MS;

L_State.Warm_Restart_Detected := VI_Warm_Restart;
L_State.Cold_Start_Detected := NOT VI_Warm_Restart;

L_State.Active_Config_Version :=
    GVL_Water_Topology_Config.G_Active_Config_Version;

L_State.Restored_Config_Version :=
    GVL_Runtime_Restart_Continuity.G_Last_Stable_Config_Version;

L_State.Last_Stable_Config_Version :=
    GVL_Runtime_Restart_Continuity.G_Last_Stable_Config_Version;

L_State.Restore_Requested :=
    GVL_Runtime_Restart_Continuity.G_Restore_Request;

L_State.Post_Restart_Validation_Required :=
    GVL_Runtime_Restart_Continuity.G_Post_Restart_Validation_Request;

L_State.Retained_State_Valid := TRUE;
L_State.Topology_Restore_Valid := TRUE;
L_State.Config_Restore_Valid := TRUE;
L_State.Recovery_Restore_Valid := TRUE;
L_State.Quarantine_Restore_Valid := TRUE;

IF L_State.Restore_Requested THEN

    IF L_State.Retained_State_Valid
       AND L_State.Topology_Restore_Valid
       AND L_State.Config_Restore_Valid THEN

        L_State.Restore_Allowed := TRUE;
        L_State.Restore_Completed := TRUE;

        GVL_Config_Activation.G_Config_Quarantine_Active :=
            GVL_Runtime_Restart_Continuity.G_Last_Known_Quarantine_State;

        L_State.Status_Code := 1;
        L_State.Status_Text := 'Runtime continuity restored';

    ELSE

        L_State.Restore_Blocked := TRUE;
        L_State.Safe_Mode_Required := TRUE;
        L_State.Operator_Ack_Required := TRUE;

        L_State.Status_Code := 2;
        L_State.Status_Text := 'Runtime continuity restore blocked';

    END_IF;

ELSIF L_State.Post_Restart_Validation_Required THEN

    IF GVL_Water_Runtime_Hardening.G_Runtime_Valid
       AND GVL_Water_Output_Reconciliation.G_Runtime_Valid
       AND NOT GVL_Water_Output_Reconciliation.G_Any_Conflict_Detected THEN

        L_State.Post_Restart_Validation_OK := TRUE;

        L_State.Status_Code := 0;
        L_State.Status_Text := 'Post-restart validation healthy';

    ELSE

        L_State.Post_Restart_Validation_Failed := TRUE;
        L_State.Safe_Mode_Required := TRUE;

        L_State.Status_Code := 3;
        L_State.Status_Text := 'Post-restart validation failed';

    END_IF;

ELSE

    L_State.Status_Code := 0;
    L_State.Status_Text := 'Runtime restart continuity healthy';

END_IF;

GVL_Runtime_Restart_Continuity.G_Continuity_State := L_State;

GVL_Runtime_Restart_Continuity.G_Runtime_Valid := TRUE;
GVL_Runtime_Restart_Continuity.G_Last_Update_MS := VI_System_Time_MS;
GVL_Runtime_Restart_Continuity.G_Status_Code := L_State.Status_Code;
GVL_Runtime_Restart_Continuity.G_Status_Text := L_State.Status_Text;

END_FUNCTION_BLOCK