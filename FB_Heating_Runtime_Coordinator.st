// ==============================================================================
// Heating runtime coordinator
// Safe orchestration shell.
// DOES NOT own heating logic.
// DOES NOT own diagnostics.
// DOES NOT own OpenTherm transport.
// DOES NOT own safety.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Runtime_Coordinator
VAR_INPUT
    VI_Enable : BOOL;
END_VAR
VAR_OUTPUT
    VO_Run_DHW_Phase : BOOL;
    VO_Run_Heating_Phase : BOOL;
    VO_Run_Service_Gating_Phase : BOOL;
    VO_Run_State_Publication_Phase : BOOL;
    VO_Run_Diagnostics_Phase : BOOL;
    VO_Run_Output_Projection_Phase : BOOL;

    VO_Runtime_Ready : BOOL;
    VO_Runtime_Fault : BOOL;
    VO_Runtime_Status_Text : STRING(128);
END_VAR

// ======================================================
// DEFAULTS
// ======================================================
VO_Run_DHW_Phase := FALSE;
VO_Run_Heating_Phase := FALSE;
VO_Run_Service_Gating_Phase := FALSE;
VO_Run_State_Publication_Phase := FALSE;
VO_Run_Diagnostics_Phase := FALSE;
VO_Run_Output_Projection_Phase := FALSE;

VO_Runtime_Ready := FALSE;
VO_Runtime_Fault := FALSE;
VO_Runtime_Status_Text := 'Heating runtime coordinator disabled';

IF NOT VI_Enable THEN
    RETURN;
END_IF;

// ======================================================
// LIVE RUNTIME CONTRACT
// ======================================================
// Phase 1
// DHW MUST execute first.
VO_Run_DHW_Phase := TRUE;

// Phase 2
// Heating runtime executes after DHW demand generation.
VO_Run_Heating_Phase := TRUE;

// Phase 3
// Service/failsafe gating executes after runtime decisions.
VO_Run_Service_Gating_Phase := TRUE;

// Phase 4
// Runtime state publication executes before diagnostics.
VO_Run_State_Publication_Phase := TRUE;

// Phase 5
// Diagnostics/explainability executes after state publication.
VO_Run_Diagnostics_Phase := TRUE;

// Phase 6
// Output projection executes last.
VO_Run_Output_Projection_Phase := TRUE;

// ======================================================
// STATUS
// ======================================================
VO_Runtime_Ready := TRUE;
VO_Runtime_Fault := FALSE;
VO_Runtime_Status_Text := 'Heating runtime coordinator active';

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_Coordinator <<<
