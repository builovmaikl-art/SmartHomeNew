// ==============================================================================
// Heating runtime event reconstruction engine
// Read-only runtime forensic reconstruction layer.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Runtime_Event_Reconstruction_Engine
VAR_INPUT
    VI_Enable : BOOL;
    VI_Node : ST_Heating_Runtime_Causality_Node;
    VI_Edge : ST_Heating_Runtime_Causality_Edge;
    VI_System_Time_MS : UDINT;
END_VAR
VAR_OUTPUT
    VO_Event : ST_Heating_Runtime_Blackbox_Event;
END_VAR

// ======================================================
// DETERMINISTIC DEFAULTS
// ======================================================
VO_Event.Event_ID := 0;
VO_Event.Event_Active := FALSE;

VO_Event.Runtime_Phase :=
    E_Heating_Runtime_Phase.HRP_DISABLED;

VO_Event.Event_Start_MS := 0;
VO_Event.Event_End_MS := 0;
VO_Event.Event_Duration_MS := 0;

VO_Event.Runtime_Degraded := FALSE;
VO_Event.Runtime_Fault := FALSE;

VO_Event.Cascade_Degraded := FALSE;
VO_Event.Cascade_Boiler_Loss := FALSE;

VO_Event.OpenTherm_Degraded := FALSE;
VO_Event.OpenTherm_Command_Invalid := FALSE;

VO_Event.Sequencing_Invalid := FALSE;
VO_Event.Ownership_Invalid := FALSE;
VO_Event.Synchronization_Invalid := FALSE;

VO_Event.Root_Cause_Candidate := FALSE;
VO_Event.Critical_Path := FALSE;

VO_Event.Status_Code := 0;
VO_Event.Status_Text := 'Heating runtime reconstruction engine disabled';

IF NOT VI_Enable THEN
    RETURN;
END_IF;

// ======================================================
// EVENT RECONSTRUCTION
// ======================================================
VO_Event.Event_ID := VI_System_Time_MS;
VO_Event.Event_Active := VI_Node.Node_Active;

VO_Event.Runtime_Phase :=
    E_Heating_Runtime_Phase.HRP_COMPLETE;

VO_Event.Event_Start_MS := VI_System_Time_MS;
VO_Event.Event_End_MS := VI_System_Time_MS;
VO_Event.Event_Duration_MS := 0;

VO_Event.Runtime_Degraded :=
    VI_Node.Runtime_Degraded;

VO_Event.Runtime_Fault :=
    VI_Node.Runtime_Fault;

VO_Event.Cascade_Degraded :=
    VI_Node.Cascade_Degraded;

VO_Event.Cascade_Boiler_Loss :=
    VI_Node.Cascade_Boiler_Loss;

VO_Event.OpenTherm_Degraded :=
    VI_Node.OpenTherm_Degraded;

VO_Event.OpenTherm_Command_Invalid :=
    VI_Node.OpenTherm_Command_Invalid;

VO_Event.Sequencing_Invalid :=
    VI_Node.Sequencing_Invalid;

VO_Event.Ownership_Invalid :=
    VI_Node.Ownership_Invalid;

VO_Event.Synchronization_Invalid :=
    VI_Node.Synchronization_Invalid;

VO_Event.Root_Cause_Candidate :=
    VI_Node.Root_Cause_Candidate;

VO_Event.Critical_Path :=
    VI_Edge.Critical_Path;

// ======================================================
// STATUS
// ======================================================
IF VO_Event.Root_Cause_Candidate THEN
    VO_Event.Status_Code := 900;
    VO_Event.Status_Text := 'Heating runtime root-cause reconstructed';
ELSE
    VO_Event.Status_Code := 1;
    VO_Event.Status_Text := 'Heating runtime event reconstructed';
END_IF;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_Event_Reconstruction_Engine <<<
