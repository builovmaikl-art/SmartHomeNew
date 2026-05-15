FUNCTION_BLOCK FB_Config_Activation_Runtime
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
END_VAR
VAR
    L_i : INT;
    L_State : ST_Config_Activation_State;
    L_Staged_Valid : BOOL;
END_VAR

IF NOT VI_Enable THEN
    GVL_Config_Activation.G_Activation_Runtime_Valid := FALSE;
    RETURN;
END_IF;

L_State := (Runtime_Valid := TRUE);
L_State.Runtime_System_Time_MS := VI_System_Time_MS;

L_State.Active_Version :=
    GVL_Water_Topology_Config.G_Active_Config_Version;

L_State.Staged_Version :=
    GVL_Config_Activation.G_Staged_Config_Version;

L_State.Previous_Stable_Version :=
    GVL_Config_Activation.G_Last_Stable_Config_Version;

L_State.Activation_Requested :=
    GVL_Config_Activation.G_Activation_Request;

L_State.Rollback_Requested :=
    GVL_Config_Activation.G_Rollback_Request;

L_State.Rollback_Available :=
    GVL_Config_Activation.G_Last_Stable_Config_Version <> 0;

L_Staged_Valid := TRUE;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_FLOOD_SENSORS DO

    IF GVL_Config_Activation.G_Staged_Topology_Config[L_i].Primary_Valve_Group_Id = 0 THEN
        L_Staged_Valid := FALSE;
    END_IF;

END_FOR;

L_State.Staged_Config_Valid := L_Staged_Valid;
L_State.Migration_Compatible := TRUE;

IF L_State.Rollback_Requested
   AND L_State.Rollback_Available THEN

    L_State.Rollback_Active := TRUE;
    L_State.Activation_Blocked := TRUE;

    GVL_Config_Activation.G_Config_Quarantine_Active := FALSE;

    L_State.Status_Code := 3;
    L_State.Status_Text := 'Rollback activation active';

ELSIF L_State.Activation_Requested THEN

    IF NOT L_State.Staged_Config_Valid THEN

        L_State.Activation_Blocked := TRUE;
        L_State.Config_Quarantine_Active := TRUE;

        GVL_Config_Activation.G_Config_Quarantine_Active := TRUE;

        L_State.Status_Code := 2;
        L_State.Status_Text := 'Config activation quarantined';

    ELSE

        L_State.Activation_Allowed := TRUE;

        GVL_Water_Topology_Config_Source.G_Source_Version :=
            L_State.Staged_Version;

        FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_FLOOD_SENSORS DO

            GVL_Water_Topology_Config_Source.G_Source_Record[L_i] :=
                GVL_Config_Activation.G_Staged_Topology_Config[L_i];

        END_FOR;

        GVL_Water_Topology_Config_Source.G_Source_Valid := TRUE;
        GVL_Water_Topology_Config_Source.G_Source_Activated_MS := VI_System_Time_MS;

        GVL_Config_Activation.G_Last_Stable_Config_Version :=
            L_State.Staged_Version;

        GVL_Config_Activation.G_Config_Quarantine_Active := FALSE;

        L_State.Status_Code := 1;
        L_State.Status_Text := 'Config activation completed';

    END_IF;

ELSE

    L_State.Status_Code := 0;
    L_State.Status_Text := 'Config activation runtime healthy';

END_IF;

GVL_Config_Activation.G_Activation_State := L_State;

GVL_Config_Activation.G_Activation_Runtime_Valid := TRUE;
GVL_Config_Activation.G_Last_Update_MS := VI_System_Time_MS;
GVL_Config_Activation.G_Status_Code := L_State.Status_Code;
GVL_Config_Activation.G_Status_Text := L_State.Status_Text;

END_FUNCTION_BLOCK