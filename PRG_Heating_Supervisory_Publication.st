PROGRAM PRG_Heating_Supervisory_Publication
VAR
    fbCircuitExplainabilityAdapter : FB_Heating_Circuit_Explainability_Adapter;
    fbSourceStabilityObserver : FB_Heating_Source_Stability_Observer;
    fbSupervisoryEnrichment : FB_Heating_Runtime_Supervisory_Enrichment;
    fbSupervisoryPublicationAdapter : FB_Heating_Runtime_Supervisory_Publication_Adapter;

    L_i : INT;
    L_Cascade_Boiler_Count : UINT;
    L_OT_Command_Valid : BOOL;
    L_Runtime_Context : ST_Heating_Runtime_Context;
    L_Causality_Node : ST_Heating_Runtime_Causality_Node;
    L_Causality_Edge : ST_Heating_Runtime_Causality_Edge;
    L_Blackbox_Event : ST_Heating_Runtime_Blackbox_Event;
    L_Predictive_State : ST_Heating_Runtime_Predictive_State;
    L_Status_Code : UINT;
    L_Status_Text : STRING(128);
END_VAR

// ==============================================================================
// Heating supervisory publication orchestration
//
// Observation-only program.
// Runs after PRG_Heating has produced canonical runtime projection.
// Does not own runtime, outputs, commands or heating authority.
// ==============================================================================

// Compatibility publication from canonical runtime projection.
fbCircuitExplainabilityAdapter(
    VI_Enable := TRUE
);

// Per-circuit predictive source-stability observation from canonical projection.
fbSourceStabilityObserver(
    VI_Enable := TRUE,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

// Build a supervisory runtime context from the published runtime observation.
// This is an observation projection only. It does not mutate runtime execution.
L_Runtime_Context.Runtime_Enabled := GVL_Heating_Runtime_Observation.G_Runtime_Observation.Runtime_Active;
L_Runtime_Context.Runtime_Ready := GVL_Heating_Runtime_Observation.G_Runtime_Observation.Runtime_Ready;
L_Runtime_Context.Runtime_Fault := GVL_Heating_Runtime_Observation.G_Runtime_Observation.Runtime_Fault;
L_Runtime_Context.Current_Phase := GVL_Heating_Runtime_Observation.G_Runtime_Observation.Current_Phase;

L_Runtime_Context.Allow_DHW_Phase := TRUE;
L_Runtime_Context.Allow_Heating_Phase := TRUE;
L_Runtime_Context.Allow_Service_Gating_Phase := TRUE;
L_Runtime_Context.Allow_State_Publication_Phase := TRUE;
L_Runtime_Context.Allow_Diagnostics_Phase := TRUE;
L_Runtime_Context.Allow_Output_Projection_Phase := TRUE;

L_Runtime_Context.DHW_Executed := GVL_Heating_Runtime_Observation.G_Runtime_Observation.DHW_Heating_Active;
L_Runtime_Context.Heating_Executed := GVL_Heating_Runtime_Observation.G_Runtime_Observation.Heating_Runtime_Active;
L_Runtime_Context.Service_Gating_Executed := TRUE;
L_Runtime_Context.State_Publication_Executed := GVL_Heating_Runtime_Observation.G_Runtime_Observation.Heating_Output_Active;
L_Runtime_Context.Diagnostics_Executed := GVL_Heating_Runtime_Observation.G_Runtime_Observation.Diagnostics_Active;
L_Runtime_Context.Output_Projection_Executed := GVL_Heating_Runtime_Observation.G_Runtime_Observation.Output_Projection_Last_Observed;

L_Runtime_Context.DHW_Before_Heating_Valid := GVL_Heating_Runtime_Observation.G_Runtime_Observation.DHW_Before_Heating_Observed;
L_Runtime_Context.State_Publication_Before_Diagnostics_Valid := GVL_Heating_Runtime_Observation.G_Runtime_Observation.Diagnostics_After_Publication_Observed;
L_Runtime_Context.Output_Projection_Last_Valid := GVL_Heating_Runtime_Observation.G_Runtime_Observation.Output_Projection_Last_Observed;

L_Runtime_Context.Diagnostics_Isolation_Valid := GVL_Heating_Runtime_Observation.G_Runtime_Observation.Diagnostics_Ownership_Valid;
L_Runtime_Context.Explainability_Isolation_Valid := GVL_Heating_Runtime_Observation.G_Runtime_Observation.Explainability_Active;
L_Runtime_Context.Safety_Isolation_Valid := GVL_Heating_Runtime_Observation.G_Runtime_Observation.Safety_Ownership_Valid;
L_Runtime_Context.OpenTherm_Ownership_Valid := GVL_Heating_Runtime_Observation.G_Runtime_Observation.OpenTherm_Ownership_Valid;
L_Runtime_Context.Cascade_Ownership_Valid := GVL_Heating_Runtime_Observation.G_Runtime_Observation.Cascade_Ownership_Valid;

L_Runtime_Context.Runtime_Status_Code := GVL_Heating_Runtime_Observation.G_Runtime_Observation.Observation_Status_Code;
L_Runtime_Context.Runtime_Status_Text := GVL_Heating_Runtime_Observation.G_Runtime_Observation.Observation_Status_Text;

// Lightweight OT/cascade observation for supervisory enrichment context.
L_Cascade_Boiler_Count := 0;
L_OT_Command_Valid := TRUE;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BOILERS DO
    IF GVL_STATE.G_Boiler_OT_Online[L_i] THEN
        L_Cascade_Boiler_Count := L_Cascade_Boiler_Count + 1;
    END_IF;

    IF GVL_STATE.G_Boiler_OT_Enable[L_i] AND NOT GVL_STATE.G_Boiler_OT_Online[L_i] THEN
        L_OT_Command_Valid := FALSE;
    END_IF;
END_FOR;

// Supervisory enrichment owns timeline/event/reconstruction ingestion.
fbSupervisoryEnrichment(
    VI_Enable := TRUE,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Runtime_Context := L_Runtime_Context,
    VI_Phase_Event := GVL_Heating_Runtime_Explainability.G_Runtime_Phase_Event,
    VI_Anomaly := GVL_Heating_Runtime_Explainability.G_Runtime_Anomaly,
    VI_Cascade_Boiler_Count := L_Cascade_Boiler_Count,
    VI_OT_Command_Valid := L_OT_Command_Valid,
    VIO_Event_Buffer := GVL_Heating_Runtime_Explainability.G_Runtime_Event_Buffer,
    VIO_Execution_Timeline := GVL_Heating_Runtime_Explainability.G_Runtime_Execution_Timeline,
    VO_Causality_Node => L_Causality_Node,
    VO_Causality_Edge => L_Causality_Edge,
    VO_Blackbox_Event => L_Blackbox_Event,
    VO_Predictive_State => L_Predictive_State,
    VO_Status_Code => L_Status_Code,
    VO_Status_Text => L_Status_Text
);

// Canonical supervisory publication surface.
fbSupervisoryPublicationAdapter(
    VI_Enable := TRUE,
    VI_Predictive_State := L_Predictive_State,
    VI_Causality_Node := L_Causality_Node,
    VI_Causality_Edge := L_Causality_Edge,
    VI_Blackbox_Event := L_Blackbox_Event,
    VI_Anomaly := GVL_Heating_Runtime_Explainability.G_Runtime_Anomaly
);

// Keep existing runtime explainability GVL as a compatibility publication surface.
GVL_Heating_Runtime_Explainability.G_Runtime_Blackbox_Event := L_Blackbox_Event;
GVL_Heating_Runtime_Explainability.G_Runtime_Predictive_State := L_Predictive_State;
GVL_Heating_Runtime_Explainability.G_Runtime_Explainability_Publication_Valid := TRUE;
GVL_Heating_Runtime_Explainability.G_Runtime_Explainability_Status_Code := L_Status_Code;
GVL_Heating_Runtime_Explainability.G_Runtime_Explainability_Status_Text := L_Status_Text;

// >>> BULK_SYNC_ANCHOR: PRG_Heating_Supervisory_Publication <<<
END_PROGRAM
