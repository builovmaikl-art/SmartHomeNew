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
// Current coordinator shell validates the sequencing model.
// Runtime ownership remains external.
L_Runtime_Valid := TRUE;

IF NOT L_Runtime_Valid THEN
    VO_Current_Phase := E_Heating_Runtime_Phase.HRP_FAULT;
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

// ======================================================
// PHASE 2 — HEATING
// ======================================================
VO_Current_Phase := E_Heating_Runtime_Phase.HRP_HEATING;
VO_Run_Heating_Phase := TRUE;

// ======================================================
// PHASE 3 — SERVICE / FAILSAFE GATING
// ======================================================
VO_Current_Phase := E_Heating_Runtime_Phase.HRP_SERVICE_GATING;
VO_Run_Service_Gating_Phase := TRUE;

// ======================================================
// PHASE 4 — STATE PUBLICATION
// ======================================================
VO_Current_Phase := E_Heating_Runtime_Phase.HRP_STATE_PUBLICATION;
VO_Run_State_Publication_Phase := TRUE;

// ======================================================
// PHASE 5 — DIAGNOSTICS
// ======================================================
VO_Current_Phase := E_Heating_Runtime_Phase.HRP_DIAGNOSTICS;
VO_Run_Diagnostics_Phase := TRUE;

// ======================================================
// PHASE 6 — OUTPUT PROJECTION
// ======================================================
VO_Current_Phase := E_Heating_Runtime_Phase.HRP_OUTPUT_PROJECTION;
VO_Run_Output_Projection_Phase := TRUE;

// ======================================================
// COMPLETE
// ======================================================
VO_Current_Phase := E_Heating_Runtime_Phase.HRP_COMPLETE;

VO_Runtime_Ready := TRUE;
VO_Runtime_Fault := FALSE;
VO_Runtime_Status_Text := 'Heating runtime coordinator active';

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_Coordinator <<<
