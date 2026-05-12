// ==============================================================================
// Heating runtime observer phase
// Owns governed observer authorization and finalized-state observer publication.
// Does NOT own heating control or output decisions.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Runtime_Observer_Phase
VAR_INPUT
    VI_Authorization_Stage : BOOL;
    VI_Finalization_Stage : BOOL;
    VI_Runtime_Context : ST_Heating_Runtime_Context;
    VI_Diagnostics_Valid : BOOL;
END_VAR
VAR_OUTPUT
    VO_Authorization_Executed : BOOL;
    VO_Finalization_Executed : BOOL;
    VO_Observer_Valid : BOOL;
END_VAR
VAR
    fbRuntimeObserver : FB_Heating_Runtime_Observer;
    fbRuntimeObserverAuthorization : FB_Heating_Runtime_Observer_Authorization;
    L_Enable_Last : BOOL := FALSE;
    L_Activation_Stabilized : BOOL := FALSE;
END_VAR

VO_Authorization_Executed := FALSE;
VO_Finalization_Executed := FALSE;
VO_Observer_Valid := FALSE;

// ======================================================
// GOVERNED OBSERVER AUTHORIZATION EVALUATION
// ======================================================
IF VI_Authorization_Stage THEN

    GVL_Heating_Runtime_Observer.G_Runtime_Observer_Lifecycle_State :=
        E_Runtime_Observer_Lifecycle_State.ROS_AUTHORIZATION_PENDING;
    GVL_Heating_Runtime_Observation.G_Runtime_Observer_Lifecycle_State :=
        E_Runtime_Observer_Lifecycle_State.ROS_AUTHORIZATION_PENDING;
    GVL_Heating_Runtime_Observation.G_Runtime_Observer_Lifecycle_Code := 10;
    GVL_Heating_Runtime_Observation.G_Runtime_Observer_Lifecycle_Text :=
        'Heating runtime observer authorization pending';
    GVL_Heating_Runtime_Observation.G_Runtime_Observer_Commissioning_Active :=
        GVL_Heating_Runtime_Observer.G_Runtime_Observer_Enable_Request;

    fbRuntimeObserverAuthorization(
        VI_Enable_Request := GVL_Heating_Runtime_Observer.G_Runtime_Observer_Enable_Request,
        VI_Bootstrap_Mode := GVL_Heating_Runtime_Observer.G_Runtime_Observer_Bootstrap_Mode,
        VI_Passive_Mode := GVL_Heating_Runtime_Observer.G_Runtime_Observer_Passive_Mode,
        VI_ReadOnly_Mode := GVL_Heating_Runtime_Observer.G_Runtime_Observer_ReadOnly_Mode,
        VI_Governance_Locked := GVL_Heating_Runtime_Observer.G_Runtime_Observer_Governance_Locked,
        VI_Runtime_Authority_Disabled := GVL_Heating_Runtime_Observer.G_Runtime_Observer_Runtime_Authority_Disabled,
        VI_Writable_Exports_Disabled := GVL_Heating_Runtime_Observer.G_Runtime_Observer_Writable_Exports_Disabled
    );

    GVL_Heating_Runtime_Observer.G_Runtime_Observer_Enable_Authorized :=
        fbRuntimeObserverAuthorization.VO_Enable_Authorized;

    GVL_Heating_Runtime_Observer.G_Runtime_Observer_Enable_Effective :=
        fbRuntimeObserverAuthorization.VO_Enable_Effective;

    GVL_Heating_Runtime_Observer.G_Runtime_Observer_Authorization_Valid :=
        fbRuntimeObserverAuthorization.VO_Authorization_Valid;

    GVL_Heating_Runtime_Observer.G_Runtime_Observer_Authorization_Status_Code :=
        fbRuntimeObserverAuthorization.VO_Status_Code;

    GVL_Heating_Runtime_Observer.G_Runtime_Observer_Authorization_Status_Text :=
        fbRuntimeObserverAuthorization.VO_Status_Text;

    IF NOT GVL_Heating_Runtime_Observer.G_Runtime_Observer_Enable_Request THEN
        GVL_Heating_Runtime_Observer.G_Runtime_Observer_Lifecycle_State :=
            E_Runtime_Observer_Lifecycle_State.ROS_INACTIVE;
        GVL_Heating_Runtime_Observation.G_Runtime_Observer_Lifecycle_State :=
            E_Runtime_Observer_Lifecycle_State.ROS_INACTIVE;
        GVL_Heating_Runtime_Observation.G_Runtime_Observer_Lifecycle_Code := 0;
        GVL_Heating_Runtime_Observation.G_Runtime_Observer_Lifecycle_Text :=
            'Heating runtime observer inactive';
        GVL_Heating_Runtime_Observation.G_Runtime_Observer_Commissioning_Active := FALSE;
    ELSIF NOT GVL_Heating_Runtime_Observer.G_Runtime_Observer_Enable_Effective THEN
        GVL_Heating_Runtime_Observer.G_Runtime_Observer_Lifecycle_State :=
            E_Runtime_Observer_Lifecycle_State.ROS_AUTHORIZATION_DENIED;
        GVL_Heating_Runtime_Observation.G_Runtime_Observer_Lifecycle_State :=
            E_Runtime_Observer_Lifecycle_State.ROS_AUTHORIZATION_DENIED;
        GVL_Heating_Runtime_Observation.G_Runtime_Observer_Lifecycle_Code := 20;
        GVL_Heating_Runtime_Observation.G_Runtime_Observer_Lifecycle_Text :=
            'Heating runtime observer authorization denied';
    END_IF;

    VO_Authorization_Executed := TRUE;
END_IF;

// ======================================================
// GOVERNED FINALIZED-STATE RUNTIME OBSERVER
// ======================================================
IF VI_Finalization_Stage THEN

    IF GVL_Heating_Runtime_Observer.G_Runtime_Observer_Enable_Effective THEN

        GVL_Heating_Runtime_Observer.G_Runtime_Observer_Rollback_Validated := FALSE;

        IF NOT L_Enable_Last THEN
            L_Activation_Stabilized := FALSE;

            GVL_Heating_Runtime_Observer.G_Runtime_Observer_Lifecycle_State :=
                E_Runtime_Observer_Lifecycle_State.ROS_STABILIZATION;
            GVL_Heating_Runtime_Observation.G_Runtime_Observer_Lifecycle_State :=
                E_Runtime_Observer_Lifecycle_State.ROS_STABILIZATION;
            GVL_Heating_Runtime_Observation.G_Runtime_Observer_Lifecycle_Code := 30;
            GVL_Heating_Runtime_Observation.G_Runtime_Observer_Lifecycle_Text :=
                'Heating runtime observer stabilization active';

            GVL_Heating_Runtime_Observation.G_Runtime_Observer_Commissioning_Required := TRUE;
            GVL_Heating_Runtime_Observation.G_Runtime_Observer_Commissioning_Active := TRUE;
            GVL_Heating_Runtime_Observation.G_Runtime_Observer_Commissioning_Complete := FALSE;

            GVL_Heating_Runtime_Observation.G_Runtime_Observation_Publication_Valid := FALSE;
            GVL_Heating_Runtime_Observation.G_Runtime_Observation_Stabilization_Complete := FALSE;
            GVL_Heating_Runtime_Observation.G_Runtime_Observation_Operational := FALSE;

            GVL_Heating_Runtime_Observation.G_Runtime_Observation_Valid := FALSE;
            GVL_Heating_Runtime_Observation.G_Runtime_Observer_Ready := FALSE;
            GVL_Heating_Runtime_Observation.G_Runtime_Observer_Fault := FALSE;
            GVL_Heating_Runtime_Observation.G_Runtime_Observation_Status_Code := 100;
            GVL_Heating_Runtime_Observation.G_Runtime_Observation_Status_Text :=
                'Heating runtime observer stabilization cycle active';
        END_IF;

        fbRuntimeObserver(
            VI_Enable := TRUE,
            VI_Runtime_Context := VI_Runtime_Context,
            VI_Diagnostics_Valid := VI_Diagnostics_Valid
        );

        GVL_Heating_Runtime_Observation.G_Runtime_Observation :=
            fbRuntimeObserver.VO_Observation;

        IF L_Activation_Stabilized THEN
            GVL_Heating_Runtime_Observer.G_Runtime_Observer_Lifecycle_State :=
                E_Runtime_Observer_Lifecycle_State.ROS_OPERATIONAL;
            GVL_Heating_Runtime_Observation.G_Runtime_Observer_Lifecycle_State :=
                E_Runtime_Observer_Lifecycle_State.ROS_OPERATIONAL;
            GVL_Heating_Runtime_Observation.G_Runtime_Observer_Lifecycle_Code := 40;
            GVL_Heating_Runtime_Observation.G_Runtime_Observer_Lifecycle_Text :=
                'Heating runtime observer operational';

            GVL_Heating_Runtime_Observation.G_Runtime_Observer_Commissioning_Required := FALSE;
            GVL_Heating_Runtime_Observation.G_Runtime_Observer_Commissioning_Active := FALSE;
            GVL_Heating_Runtime_Observation.G_Runtime_Observer_Commissioning_Complete := TRUE;

            GVL_Heating_Runtime_Observation.G_Runtime_Observation_Publication_Valid := TRUE;
            GVL_Heating_Runtime_Observation.G_Runtime_Observation_Stabilization_Complete := TRUE;
            GVL_Heating_Runtime_Observation.G_Runtime_Observation_Operational := TRUE;

            GVL_Heating_Runtime_Observation.G_Runtime_Observation_Valid := TRUE;
            GVL_Heating_Runtime_Observation.G_Runtime_Observer_Ready :=
                fbRuntimeObserver.VO_Observer_Ready;
            GVL_Heating_Runtime_Observation.G_Runtime_Observer_Fault :=
                fbRuntimeObserver.VO_Observer_Fault;
            GVL_Heating_Runtime_Observation.G_Runtime_Observation_Status_Code :=
                fbRuntimeObserver.VO_Status_Code;
            GVL_Heating_Runtime_Observation.G_Runtime_Observation_Status_Text :=
                fbRuntimeObserver.VO_Status_Text;

            GVL_Heating_Runtime_Observer.G_Runtime_Observer_Activation_Validated := TRUE;
            GVL_Heating_Runtime_Observer.G_Runtime_Observer_Sequencing_Validated := TRUE;
            GVL_Heating_Runtime_Observer.G_Runtime_Observer_Publication_Validated := TRUE;
            VO_Observer_Valid := TRUE;
        ELSE
            L_Activation_Stabilized := TRUE;
        END_IF;

    ELSE
        L_Activation_Stabilized := FALSE;

        IF L_Enable_Last THEN
            GVL_Heating_Runtime_Observer.G_Runtime_Observer_Lifecycle_State :=
                E_Runtime_Observer_Lifecycle_State.ROS_ROLLBACK;
            GVL_Heating_Runtime_Observation.G_Runtime_Observer_Lifecycle_State :=
                E_Runtime_Observer_Lifecycle_State.ROS_ROLLBACK;
            GVL_Heating_Runtime_Observation.G_Runtime_Observer_Lifecycle_Code := 50;
            GVL_Heating_Runtime_Observation.G_Runtime_Observer_Lifecycle_Text :=
                'Heating runtime observer rollback cleanup completed';
        ELSIF GVL_Heating_Runtime_Observer.G_Runtime_Observer_Enable_Request THEN
            GVL_Heating_Runtime_Observer.G_Runtime_Observer_Lifecycle_State :=
                E_Runtime_Observer_Lifecycle_State.ROS_AUTHORIZATION_DENIED;
            GVL_Heating_Runtime_Observation.G_Runtime_Observer_Lifecycle_State :=
                E_Runtime_Observer_Lifecycle_State.ROS_AUTHORIZATION_DENIED;
            GVL_Heating_Runtime_Observation.G_Runtime_Observer_Lifecycle_Code := 20;
            GVL_Heating_Runtime_Observation.G_Runtime_Observer_Lifecycle_Text :=
                'Heating runtime observer authorization denied';
        ELSE
            GVL_Heating_Runtime_Observer.G_Runtime_Observer_Lifecycle_State :=
                E_Runtime_Observer_Lifecycle_State.ROS_INACTIVE;
            GVL_Heating_Runtime_Observation.G_Runtime_Observer_Lifecycle_State :=
                E_Runtime_Observer_Lifecycle_State.ROS_INACTIVE;
            GVL_Heating_Runtime_Observation.G_Runtime_Observer_Lifecycle_Code := 0;
            GVL_Heating_Runtime_Observation.G_Runtime_Observer_Lifecycle_Text :=
                'Heating runtime observer inactive';
        END_IF;

        GVL_Heating_Runtime_Observation.G_Runtime_Observer_Commissioning_Required := TRUE;
        GVL_Heating_Runtime_Observation.G_Runtime_Observer_Commissioning_Active := FALSE;
        GVL_Heating_Runtime_Observation.G_Runtime_Observer_Commissioning_Complete := FALSE;

        GVL_Heating_Runtime_Observation.G_Runtime_Observation.Runtime_Active := FALSE;
        GVL_Heating_Runtime_Observation.G_Runtime_Observation.Runtime_Ready := FALSE;
        GVL_Heating_Runtime_Observation.G_Runtime_Observation.Runtime_Fault := FALSE;
        GVL_Heating_Runtime_Observation.G_Runtime_Observation.Current_Phase := E_Heating_Runtime_Phase.HRP_DISABLED;

        GVL_Heating_Runtime_Observation.G_Runtime_Observation.DHW_Demand_Active := FALSE;
        GVL_Heating_Runtime_Observation.G_Runtime_Observation.DHW_Heating_Active := FALSE;
        GVL_Heating_Runtime_Observation.G_Runtime_Observation.DHW_Circulation_Active := FALSE;

        GVL_Heating_Runtime_Observation.G_Runtime_Observation.Heating_Demand_Active := FALSE;
        GVL_Heating_Runtime_Observation.G_Runtime_Observation.Heating_Runtime_Active := FALSE;
        GVL_Heating_Runtime_Observation.G_Runtime_Observation.Heating_Output_Active := FALSE;

        GVL_Heating_Runtime_Observation.G_Runtime_Observation.Cascade_Available := FALSE;
        GVL_Heating_Runtime_Observation.G_Runtime_Observation.Cascade_Degraded := FALSE;
        GVL_Heating_Runtime_Observation.G_Runtime_Observation.Cascade_Active_Boilers := 0;
        GVL_Heating_Runtime_Observation.G_Runtime_Observation.Cascade_Available_Boilers := 0;

        GVL_Heating_Runtime_Observation.G_Runtime_Observation.OpenTherm_Online := FALSE;
        GVL_Heating_Runtime_Observation.G_Runtime_Observation.OpenTherm_Command_Valid := FALSE;
        GVL_Heating_Runtime_Observation.G_Runtime_Observation.OpenTherm_Transport_Degraded := FALSE;

        GVL_Heating_Runtime_Observation.G_Runtime_Observation.Diagnostics_Active := FALSE;
        GVL_Heating_Runtime_Observation.G_Runtime_Observation.Explainability_Active := FALSE;

        GVL_Heating_Runtime_Observation.G_Runtime_Observation.DHW_Before_Heating_Observed := FALSE;
        GVL_Heating_Runtime_Observation.G_Runtime_Observation.Diagnostics_After_Publication_Observed := FALSE;
        GVL_Heating_Runtime_Observation.G_Runtime_Observation.Output_Projection_Last_Observed := FALSE;

        GVL_Heating_Runtime_Observation.G_Runtime_Observation.Runtime_Ownership_Valid := FALSE;
        GVL_Heating_Runtime_Observation.G_Runtime_Observation.Diagnostics_Ownership_Valid := FALSE;
        GVL_Heating_Runtime_Observation.G_Runtime_Observation.OpenTherm_Ownership_Valid := FALSE;
        GVL_Heating_Runtime_Observation.G_Runtime_Observation.Cascade_Ownership_Valid := FALSE;
        GVL_Heating_Runtime_Observation.G_Runtime_Observation.Safety_Ownership_Valid := FALSE;

        GVL_Heating_Runtime_Observation.G_Runtime_Observation.Observation_Status_Code := 0;
        GVL_Heating_Runtime_Observation.G_Runtime_Observation.Observation_Status_Text :=
            'Heating runtime observation inactive';

        GVL_Heating_Runtime_Observation.G_Runtime_Observation_Publication_Valid := FALSE;
        GVL_Heating_Runtime_Observation.G_Runtime_Observation_Stabilization_Complete := FALSE;
        GVL_Heating_Runtime_Observation.G_Runtime_Observation_Operational := FALSE;

        GVL_Heating_Runtime_Observation.G_Runtime_Observation_Valid := FALSE;
        GVL_Heating_Runtime_Observation.G_Runtime_Observer_Ready := FALSE;
        GVL_Heating_Runtime_Observation.G_Runtime_Observer_Fault := FALSE;
        GVL_Heating_Runtime_Observation.G_Runtime_Observation_Status_Code := 0;
        GVL_Heating_Runtime_Observation.G_Runtime_Observation_Status_Text :=
            'Heating runtime observation inactive';

        GVL_Heating_Runtime_Observer.G_Runtime_Observer_Activation_Validated := FALSE;
        GVL_Heating_Runtime_Observer.G_Runtime_Observer_Sequencing_Validated := FALSE;
        GVL_Heating_Runtime_Observer.G_Runtime_Observer_Publication_Validated := FALSE;
        GVL_Heating_Runtime_Observer.G_Runtime_Observer_Rollback_Validated := TRUE;
    END_IF;

    L_Enable_Last :=
        GVL_Heating_Runtime_Observer.G_Runtime_Observer_Enable_Effective;

    VO_Finalization_Executed := TRUE;
END_IF;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_Observer_Phase <<<
