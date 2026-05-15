PROGRAM PRG_Heating_Supervisory_Publication
VAR
    fbCircuitExplainabilityAdapter : FB_Heating_Circuit_Explainability_Adapter;
    fbSourceStabilityObserver : FB_Heating_Source_Stability_Observer;
    fbSupervisoryEnrichment : FB_Heating_Runtime_Supervisory_Enrichment;
    fbSupervisoryPublicationAdapter : FB_Heating_Runtime_Supervisory_Publication_Adapter;

    L_i : INT;
    L_Cascade_Boiler_Count : UINT;
    L_OT_Command_Valid : BOOL;
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
    VI_Runtime_Context := GVL_Heating_Runtime_Observation.G_Runtime_Context,
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
