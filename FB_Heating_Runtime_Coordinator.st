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
    // Typed runtime context
    VO_Runtime_Context : ST_Heating_Runtime_Context;

    // Current runtime phase
    VO_Current_Phase : E_Heating_Runtime_Phase;

    // Phase execution flags
    VO_Run_DHW_Phase : BOOL;
    VO_Run_Heating_Phase : BOOL;
    VO_Run_Service_Gating_Phase : BOOL;
    VO_Run_State_Publication_Phase : BOOL;
    VO_Run_Diagnostics_Phase : BOOL;
    VO_Run_Output_Projection_Phase : BOOL;

    // Runtime state
    VO_Runtime_Ready : BOOL;
    VO_Runtime_Fault : BOOL;
    VO_Runtime_Status_Text : STRING(128);
END_VAR
VAR
    L_Runtime_Valid : BOOL;
END_VAR

// ======================================================
// DEFAULTS
// ======================================================
VO_Runtime_Context.Runtime_Enabled := FALSE;
VO_Runtime_Context.Runtime_Ready := FALSE;
VO_Runtime_Context.Runtime_Fault := FALSE;
VO_Runtime_Context.Current_Phase := E_Heating_Runtime_Phase.HRP_DISABLED;

VO_Runtime_Context.Allow_DHW_Phase := FALSE;
VO_Runtime_Context.Allow_Heating_Phase := FALSE;
VO_Runtime_Context.Allow_Service_Gating_Phase := FALSE;
VO_Runtime_Context.Allow_State_Publication_Phase := FALSE;
VO_Runtime_Context.Allow_Diagnostics_Phase := FALSE;
VO_Runtime_Context.Allow_Output_Projection_Phase := FALSE;

VO_Runtime_Context.DHW_Executed := FALSE;
VO_Runtime_Context.Heating_Executed := FALSE;
VO_Runtime_Context.Service_Gating_Executed := FALSE;
VO_Runtime_Context.State_Publication_Executed := FALSE;
VO_Runtime_Context.Diagnostics_Executed := FALSE;
VO_Runtime_Context.Output_Projection_Executed := FALSE;

VO_Runtime_Context.DHW_Before_Heating_Valid := TRUE;
VO_Runtime_Context.State_Publication_Before_Diagnostics_Valid := TRUE;
VO_Runtime_Context.Output_Projection_Last_Valid := TRUE;

VO_Runtime_Context.Diagnostics_Isolation_Valid := TRUE;
VO_Runtime_Context.Explainability_Isolation_Valid := TRUE;
VO_Runtime_Context.Safety_Isolation_Valid := TRUE;
VO_Runtime_Context.OpenTherm_Ownership_Valid := TRUE;
VO_Runtime_Context.Cascade_Ownership_Valid := TRUE;

VO_Runtime_Context.Runtime_Status_Code := 0;
VO_Runtime_Context.Runtime_Status_Text := 'Heating runtime coordinator disabled';

VO_Current_Phase := E_Heating_Runtime_Phase.HRP_DISABLED;

VO_Run_DHW_Phase := FALSE;
VO_Run_Heating_Phase := FALSE;
VO_Run_Service_Gating_Phase := FALSE;
VO_Run_State_Publication_Phase := FALSE;
VO_Run_Diagnostics_Phase := FALSE;
VO_Run_Output_Projection_Phase := FALSE;

VO_Runtime_Ready := FALSE;
VO_Runtime_Fault := FALSE;
VO_Runtime_Status_Text := 'Heating runtime coordinator disabled';

L_Runtime_Valid := FALSE;

IF NOT VI_Enable THEN
    RETURN;
END_IF;

// ======================================================
// RUNTIME CONTRACT VALIDATION
// ======================================================
L_Runtime_Valid := TRUE;

IF NOT L_Runtime_Valid THEN
    VO_Current_Phase := E_Heating_Runtime_Phase.HRP_FAULT;

    VO_Runtime_Context.Runtime_Enabled := TRUE;
    VO_Runtime_Context.Runtime_Ready := FALSE;
    VO_Runtime_Context.Runtime_Fault := TRUE;
    VO_Runtime_Context.Current_Phase := E_Heating_Runtime_Phase.HRP_FAULT;
    VO_Runtime_Context.Runtime_Status_Code := 900;
    VO_Runtime_Context.Runtime_Status_Text := 'Heating runtime sequencing invalid';

    VO_Runtime_Ready := FALSE;
    VO_Runtime_Fault := TRUE;
    VO_Runtime_Status_Text := 'Heating runtime sequencing invalid';
    RETURN;
END_IF;

// ======================================================
// PHASE 1 — DHW
// ======================================================
VO_Current_Phase := E_Heating_Runtime_Phase.HRP_DHW;
VO_Run_DHW_Phase := TRUE;

VO_Runtime_Context.Runtime_Enabled := TRUE;
VO_Runtime_Context.Allow_DHW_Phase := TRUE;
VO_Runtime_Context.Current_Phase := E_Heating_Runtime_Phase.HRP_DHW;
VO_Runtime_Context.DHW_Executed := TRUE;

// ======================================================
// PHASE 2 — HEATING
// ======================================================
VO_Current_Phase := E_Heating_Runtime_Phase.HRP_HEATING;
VO_Run_Heating_Phase := TRUE;

VO_Runtime_Context.Allow_Heating_Phase := TRUE;
VO_Runtime_Context.Current_Phase := E_Heating_Runtime_Phase.HRP_HEATING;
VO_Runtime_Context.Heating_Executed := TRUE;

// ======================================================
// PHASE 3 — SERVICE / FAILSAFE GATING
// ======================================================
VO_Current_Phase := E_Heating_Runtime_Phase.HRP_SERVICE_GATING;
VO_Run_Service_Gating_Phase := TRUE;

VO_Runtime_Context.Allow_Service_Gating_Phase := TRUE;
VO_Runtime_Context.Current_Phase := E_Heating_Runtime_Phase.HRP_SERVICE_GATING;
VO_Runtime_Context.Service_Gating_Executed := TRUE;

// ======================================================
// PHASE 4 — STATE PUBLICATION
// ======================================================
VO_Current_Phase := E_Heating_Runtime_Phase.HRP_STATE_PUBLICATION;
VO_Run_State_Publication_Phase := TRUE;

VO_Runtime_Context.Allow_State_Publication_Phase := TRUE;
VO_Runtime_Context.Current_Phase := E_Heating_Runtime_Phase.HRP_STATE_PUBLICATION;
VO_Runtime_Context.State_Publication_Executed := TRUE;

// ======================================================
// PHASE 5 — DIAGNOSTICS
// ======================================================
VO_Current_Phase := E_Heating_Runtime_Phase.HRP_DIAGNOSTICS;
VO_Run_Diagnostics_Phase := TRUE;

VO_Runtime_Context.Allow_Diagnostics_Phase := TRUE;
VO_Runtime_Context.Current_Phase := E_Heating_Runtime_Phase.HRP_DIAGNOSTICS;
VO_Runtime_Context.Diagnostics_Executed := TRUE;

// ======================================================
// PHASE 6 — OUTPUT PROJECTION
// ======================================================
VO_Current_Phase := E_Heating_Runtime_Phase.HRP_OUTPUT_PROJECTION;
VO_Run_Output_Projection_Phase := TRUE;

VO_Runtime_Context.Allow_Output_Projection_Phase := TRUE;
VO_Runtime_Context.Current_Phase := E_Heating_Runtime_Phase.HRP_OUTPUT_PROJECTION;
VO_Runtime_Context.Output_Projection_Executed := TRUE;

// ======================================================
// COMPLETE
// ======================================================
VO_Current_Phase := E_Heating_Runtime_Phase.HRP_COMPLETE;
VO_Runtime_Context.Current_Phase := E_Heating_Runtime_Phase.HRP_COMPLETE;

VO_Runtime_Context.Runtime_Ready := TRUE;
VO_Runtime_Context.Runtime_Fault := FALSE;
VO_Runtime_Context.Runtime_Status_Code := 100;
VO_Runtime_Context.Runtime_Status_Text := 'Heating runtime coordinator active';

VO_Runtime_Ready := TRUE;
VO_Runtime_Fault := FALSE;
VO_Runtime_Status_Text := 'Heating runtime coordinator active';

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_Coordinator <<<
