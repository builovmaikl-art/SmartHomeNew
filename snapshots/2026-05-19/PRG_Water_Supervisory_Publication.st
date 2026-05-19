PROGRAM PRG_Water_Supervisory_Publication
VAR
    fbConfigActivationRuntime : FB_Config_Activation_Runtime;
    fbHMIConfigWorkflowRuntime : FB_HMI_Config_Workflow_Runtime;
    fbRestartContinuity : FB_Runtime_Restart_Continuity;
    fbWaterHardwareBindingRuntime : FB_Water_Hardware_Binding_Runtime;
    fbWaterTopologyConfig : FB_Water_Topology_Config_Runtime;
    fbWaterLeakProjection : FB_Water_Leak_Runtime_Projection;
    fbWaterTopologyValidator : FB_Water_Hydraulic_Topology_Validator;
    fbWaterIsolationPathResolver : FB_Water_Isolation_Path_Resolver;
    fbWaterOrchestrationRuntime : FB_Water_Orchestration_Runtime;
    fbWaterIsolationProjection : FB_Water_Isolation_Runtime_Projection;
    fbWaterIsolationIntentBuilder : FB_Water_Isolation_Intent_Builder;
    fbWaterAuthorityArbitrator : FB_Water_Isolation_Authority_Arbitrator;
    fbWaterValveGovernance : FB_Water_Valve_Runtime_Governance;

    L_i : INT;
    L_State : ST_Water_Leak_Runtime_State;

    L_Any_Leak : BOOL;
    L_Any_Warning : BOOL;
    L_Any_Degraded_Mapping : BOOL;
    L_Selective_Isolation_Available : BOOL;
    L_Global_Fallback_Required : BOOL;
END_VAR

// Water/Flood supervisory publication orchestration.
//
// Runtime chain:
// config activation/workflow
//   -> restart continuity
//   -> hardware binding resolver
//   -> runtime topology config
//   -> leak semantics
//   -> topology validation
//   -> graph/path resolution
//   -> orchestration/traversal governance
//   -> isolation semantics
//   -> authority arbitration
//   -> valve governance
//   -> supervisory publication
//
// Distributed execution gates are authoritative.
// Water runtime orchestration must never bypass cluster execution policy.

fbConfigActivationRuntime(
    VI_Enable := TRUE,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

fbHMIConfigWorkflowRuntime(
    VI_Enable := TRUE,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

fbRestartContinuity(
    VI_Enable := TRUE,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Warm_Restart := GVL_Runtime_Restart_Continuity.G_Restore_Request
);

fbWaterHardwareBindingRuntime(
    VI_Enable := TRUE,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

fbWaterTopologyConfig(
    VI_Enable := TRUE,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

fbWaterLeakProjection(
    VI_Enable := TRUE,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

fbWaterTopologyValidator(
    VI_Enable := TRUE,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

fbWaterIsolationPathResolver(
    VI_Enable := GVL_Distributed_Execution_Gates.G_Can_Orchestrate,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

fbWaterOrchestrationRuntime(
    VI_Enable := GVL_Distributed_Execution_Gates.G_Can_Orchestrate,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

fbWaterIsolationProjection(
    VI_Enable := GVL_Distributed_Execution_Gates.G_Can_Execute,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

fbWaterIsolationIntentBuilder(
    VI_Enable := GVL_Distributed_Execution_Gates.G_Can_Execute
);

fbWaterAuthorityArbitrator(
    VI_Enable := GVL_Distributed_Execution_Gates.G_Can_Execute,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

fbWaterValveGovernance(
    VI_Enable := GVL_Distributed_Execution_Gates.G_Can_Own_Projection,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

L_Any_Leak := FALSE;
L_Any_Warning := FALSE;
L_Any_Degraded_Mapping := FALSE;
L_Selective_Isolation_Available := FALSE;
L_Global_Fallback_Required := FALSE;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_FLOOD_SENSORS DO

    L_State := GVL_Water_Runtime_Projection.G_Leak_Runtime_State[L_i];

    L_Any_Leak := L_Any_Leak OR L_State.Leak_Confirmed;
    L_Any_Warning := L_Any_Warning OR L_State.Leak_Warning_Active;

    L_Any_Degraded_Mapping :=
        L_Any_Degraded_Mapping
        OR GVL_Water_Orchestration.G_Traversal_State[L_i].Traversal_Conflict
        OR NOT GVL_Water_Topology_Config.G_Config_Record[L_i].Config_Valid
        OR GVL_IO_Binding_Runtime.G_Any_Invalid_Binding;

    L_Selective_Isolation_Available :=
        L_Selective_Isolation_Available
        OR GVL_Water_Orchestration.G_Traversal_State[L_i].Selective_Path_Allowed;

    L_Global_Fallback_Required :=
        L_Global_Fallback_Required
        OR GVL_Water_Orchestration.G_Traversal_State[L_i].Global_Fallback_Required;

END_FOR;

GVL_Water_Runtime_Supervisory_Publication.G_Supervisory_Valid := TRUE;
GVL_Water_Runtime_Supervisory_Publication.G_Last_Update_MS :=
    GVL_STATUS.G_System_Time_MS;

GVL_Water_Runtime_Supervisory_Publication.G_Any_Leak_Active :=
    L_Any_Leak;

GVL_Water_Runtime_Supervisory_Publication.G_Any_Warning_Active :=
    L_Any_Warning;

GVL_Water_Runtime_Supervisory_Publication.G_Any_Degraded_Mapping :=
    L_Any_Degraded_Mapping;

GVL_Water_Runtime_Supervisory_Publication.G_Selective_Isolation_Available :=
    L_Selective_Isolation_Available;

GVL_Water_Runtime_Supervisory_Publication.G_Global_Fallback_Active :=
    L_Global_Fallback_Required;

IF NOT GVL_Distributed_Execution_Gates.G_Can_Execute THEN
    GVL_Water_Runtime_Supervisory_Publication.G_Status_Code := 20;
    GVL_Water_Runtime_Supervisory_Publication.G_Status_Text :=
        'Distributed execution gates restricted';
ELSIF GVL_Config_Activation.G_Config_Quarantine_Active THEN
    GVL_Water_Runtime_Supervisory_Publication.G_Status_Code := 11;
    GVL_Water_Runtime_Supervisory_Publication.G_Status_Text :=
        'Runtime config quarantine active';
ELSIF GVL_IO_Binding_Runtime.G_Any_Invalid_Binding THEN
    GVL_Water_Runtime_Supervisory_Publication.G_Status_Code := 10;
    GVL_Water_Runtime_Supervisory_Publication.G_Status_Text :=
        'Hardware binding invalid';
ELSIF GVL_Water_Topology_Config.G_Any_Invalid_Config THEN
    GVL_Water_Runtime_Supervisory_Publication.G_Status_Code := 8;
    GVL_Water_Runtime_Supervisory_Publication.G_Status_Text :=
        'Runtime topology config invalid';
ELSIF GVL_Water_Orchestration.G_Any_Escalation_Required THEN
    GVL_Water_Runtime_Supervisory_Publication.G_Status_Code := 7;
    GVL_Water_Runtime_Supervisory_Publication.G_Status_Text :=
        'Topology-aware orchestration escalation active';
ELSIF GVL_Water_Orchestration.G_Any_Traversal_Conflict THEN
    GVL_Water_Runtime_Supervisory_Publication.G_Status_Code := 6;
    GVL_Water_Runtime_Supervisory_Publication.G_Status_Text :=
        'Traversal conflict detected';
ELSE
    GVL_Water_Runtime_Supervisory_Publication.G_Status_Code := 0;
    GVL_Water_Runtime_Supervisory_Publication.G_Status_Text :=
        'Runtime topology orchestration active';
END_IF;

// >>> BULK_SYNC_ANCHOR: PRG_Water_Supervisory_Publication <<<
END_PROGRAM