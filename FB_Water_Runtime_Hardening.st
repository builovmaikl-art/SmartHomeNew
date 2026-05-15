FUNCTION_BLOCK FB_Water_Runtime_Hardening
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
END_VAR
VAR
    L_i : INT;

    L_FSM : ST_Water_Recovery_FSM_State;
    L_Event : ST_Water_Event_Log_Record;

    L_Any_Rollback : BOOL;
    L_Any_Escalation : BOOL;
END_VAR

IF NOT VI_Enable THEN
    GVL_Water_Runtime_Hardening.G_Runtime_Valid := FALSE;
    RETURN;
END_IF;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_FLOOD_SENSORS DO

    // Recovery FSM.
    L_FSM := (Runtime_Valid := TRUE);

    L_FSM.Runtime_System_Time_MS :=
        VI_System_Time_MS;

    L_FSM.Recovery_Domain_Id :=
        GVL_Water_Topology_Config.G_Config_Record[L_i].Recovery_Domain_Id;

    L_FSM.Recovery_Requested :=
        GVL_INTENT_SAFETY.I_Water_Selective_Recovery_Allowed;

    L_FSM.Recovery_Sequencing_Active :=
        GVL_Water_Orchestration.G_Orchestration_State[L_i].Recovery_Sequence_Active;

    L_FSM.Recovery_Verification_Window_Active :=
        GVL_Water_Orchestration.G_Orchestration_State[L_i].Observation_Window_Active;

    // Conservative runtime hardening.
    IF GVL_Water_Physical_Runtime.G_Convergence_State[L_i].Escalation_Required THEN

        L_FSM.Rollback_Required := TRUE;
        L_FSM.Escalation_Required := TRUE;
        L_FSM.Operator_Ack_Required := TRUE;
        L_FSM.Recovery_Denied := TRUE;
        L_FSM.FSM_State := 100;

        L_FSM.Status_Code := 2;
        L_FSM.Status_Text :=
            'Recovery rollback escalation active';

    ELSIF L_FSM.Recovery_Requested THEN

        L_FSM.Recovery_Completed := TRUE;
        L_FSM.FSM_State := 10;

        L_FSM.Status_Code := 1;
        L_FSM.Status_Text :=
            'Recovery sequencing active';

    ELSE

        L_FSM.FSM_State := 0;

        L_FSM.Status_Code := 0;
        L_FSM.Status_Text :=
            'Recovery FSM idle';

    END_IF;

    GVL_Water_Runtime_Hardening.G_Recovery_FSM[L_i] :=
        L_FSM;

    // Runtime event publication.
    IF L_i <= 128 THEN

        L_Event := (Runtime_Valid := TRUE);

        L_Event.Event_Time_MS := VI_System_Time_MS;
        L_Event.Event_Id := TO_UINT(L_i);

        IF L_FSM.Escalation_Required THEN
            L_Event.Event_Text :=
                'Water runtime escalation active';
        ELSE
            L_Event.Event_Text :=
                'Water runtime healthy';
        END_IF;

        GVL_Water_Runtime_Hardening.G_Event_Log[L_i] :=
            L_Event;

    END_IF;

    L_Any_Rollback :=
        L_Any_Rollback
        OR L_FSM.Rollback_Required;

    L_Any_Escalation :=
        L_Any_Escalation
        OR L_FSM.Escalation_Required;

END_FOR;

GVL_Water_Runtime_Hardening.G_Runtime_Quarantine_Active :=
    L_Any_Escalation;

GVL_Water_Runtime_Hardening.G_Service_Mode_Active := FALSE;
GVL_Water_Runtime_Hardening.G_Maintenance_Mode_Active := FALSE;

GVL_Water_Runtime_Hardening.G_Any_Rollback_Required :=
    L_Any_Rollback;

GVL_Water_Runtime_Hardening.G_Any_Escalation_Required :=
    L_Any_Escalation;

GVL_Water_Runtime_Hardening.G_Runtime_Valid := TRUE;
GVL_Water_Runtime_Hardening.G_Last_Update_MS := VI_System_Time_MS;

IF L_Any_Escalation THEN
    GVL_Water_Runtime_Hardening.G_Status_Code := 2;
    GVL_Water_Runtime_Hardening.G_Status_Text :=
        'Runtime quarantine escalation active';
ELSIF L_Any_Rollback THEN
    GVL_Water_Runtime_Hardening.G_Status_Code := 1;
    GVL_Water_Runtime_Hardening.G_Status_Text :=
        'Recovery rollback active';
ELSE
    GVL_Water_Runtime_Hardening.G_Status_Code := 0;
    GVL_Water_Runtime_Hardening.G_Status_Text :=
        'Production runtime hardening active';
END_IF;

END_FUNCTION_BLOCK