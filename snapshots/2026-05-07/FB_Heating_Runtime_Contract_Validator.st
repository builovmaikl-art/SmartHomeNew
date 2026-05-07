// ==============================================================================
// Heating runtime contract validator
// Read-only orchestration validation layer.
// DOES NOT own runtime.
// DOES NOT own heating logic.
// DOES NOT own diagnostics.
// DOES NOT own OpenTherm transport.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Runtime_Contract_Validator
VAR_INPUT
    VI_Context : ST_Heating_Runtime_Context;
END_VAR
VAR_OUTPUT
    VO_Contract_Valid : BOOL;
    VO_Runtime_Ordering_Valid : BOOL;
    VO_Runtime_Isolation_Valid : BOOL;
    VO_Runtime_Status_Code : UINT;
    VO_Runtime_Status_Text : STRING(128);
END_VAR
VAR
    L_Ordering_Valid : BOOL;
    L_Isolation_Valid : BOOL;
    L_Contract_Valid : BOOL;
END_VAR

// ======================================================
// DEFAULTS
// ======================================================
VO_Contract_Valid := FALSE;
VO_Runtime_Ordering_Valid := FALSE;
VO_Runtime_Isolation_Valid := FALSE;
VO_Runtime_Status_Code := 0;
VO_Runtime_Status_Text := 'Heating runtime contract validator idle';

L_Ordering_Valid := TRUE;
L_Isolation_Valid := TRUE;
L_Contract_Valid := TRUE;

// ======================================================
// RUNTIME ORDERING VALIDATION
// ======================================================
IF NOT VI_Context.DHW_Before_Heating_Valid THEN
    L_Ordering_Valid := FALSE;
END_IF;

IF NOT VI_Context.State_Publication_Before_Diagnostics_Valid THEN
    L_Ordering_Valid := FALSE;
END_IF;

IF NOT VI_Context.Output_Projection_Last_Valid THEN
    L_Ordering_Valid := FALSE;
END_IF;

// ======================================================
// EXECUTION CONSISTENCY VALIDATION
// ======================================================
IF VI_Context.Heating_Executed AND NOT VI_Context.DHW_Executed THEN
    L_Ordering_Valid := FALSE;
END_IF;

IF VI_Context.Diagnostics_Executed AND NOT VI_Context.State_Publication_Executed THEN
    L_Ordering_Valid := FALSE;
END_IF;

IF VI_Context.Output_Projection_Executed AND NOT VI_Context.Diagnostics_Executed THEN
    L_Ordering_Valid := FALSE;
END_IF;

// ======================================================
// OWNERSHIP / ISOLATION VALIDATION
// ======================================================
IF NOT VI_Context.Diagnostics_Isolation_Valid THEN
    L_Isolation_Valid := FALSE;
END_IF;

IF NOT VI_Context.Explainability_Isolation_Valid THEN
    L_Isolation_Valid := FALSE;
END_IF;

IF NOT VI_Context.Safety_Isolation_Valid THEN
    L_Isolation_Valid := FALSE;
END_IF;

IF NOT VI_Context.OpenTherm_Ownership_Valid THEN
    L_Isolation_Valid := FALSE;
END_IF;

IF NOT VI_Context.Cascade_Ownership_Valid THEN
    L_Isolation_Valid := FALSE;
END_IF;

// ======================================================
// FINAL CONTRACT VALIDATION
// ======================================================
L_Contract_Valid :=
    L_Ordering_Valid AND
    L_Isolation_Valid AND
    NOT VI_Context.Runtime_Fault;

VO_Runtime_Ordering_Valid := L_Ordering_Valid;
VO_Runtime_Isolation_Valid := L_Isolation_Valid;
VO_Contract_Valid := L_Contract_Valid;

// ======================================================
// STATUS
// ======================================================
IF NOT L_Ordering_Valid THEN
    VO_Runtime_Status_Code := 100;
    VO_Runtime_Status_Text := 'Heating runtime ordering validation failed';

ELSIF NOT L_Isolation_Valid THEN
    VO_Runtime_Status_Code := 200;
    VO_Runtime_Status_Text := 'Heating runtime ownership isolation failed';

ELSIF VI_Context.Runtime_Fault THEN
    VO_Runtime_Status_Code := 300;
    VO_Runtime_Status_Text := 'Heating runtime fault active';

ELSE
    VO_Runtime_Status_Code := 1;
    VO_Runtime_Status_Text := 'Heating runtime contract valid';
END_IF;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_Contract_Validator <<<
