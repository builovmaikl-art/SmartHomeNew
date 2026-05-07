// ==============================================================================
// Heating runtime health observer
// Read-only orchestration health aggregation layer.
// DOES NOT own runtime.
// DOES NOT own heating logic.
// DOES NOT own diagnostics.
// DOES NOT own OpenTherm transport.
// DOES NOT own migration.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Runtime_Health_Observer
VAR_INPUT
    VI_Enable : BOOL;
    VI_Context : ST_Heating_Runtime_Context;
    VI_Bridge : ST_Heating_Runtime_Integration_Bridge;

    VI_Synchronized : BOOL;
    VI_Phase_Synchronized : BOOL;
    VI_Ownership_Synchronized : BOOL;
    VI_Sequencing_Synchronized : BOOL;
END_VAR
VAR_OUTPUT
    VO_Runtime_Healthy : BOOL;
    VO_Runtime_Degraded : BOOL;
    VO_Runtime_Critical : BOOL;

    VO_Sequencing_Healthy : BOOL;
    VO_Ownership_Healthy : BOOL;
    VO_Synchronization_Healthy : BOOL;

    VO_Status_Code : UINT;
    VO_Status_Text : STRING(128);
END_VAR
VAR
    L_Healthy : BOOL;
    L_Degraded : BOOL;
    L_Critical : BOOL;
END_VAR

// ======================================================
// DEFAULTS
// ======================================================
VO_Runtime_Healthy := FALSE;
VO_Runtime_Degraded := FALSE;
VO_Runtime_Critical := FALSE;

VO_Sequencing_Healthy := FALSE;
VO_Ownership_Healthy := FALSE;
VO_Synchronization_Healthy := FALSE;

VO_Status_Code := 0;
VO_Status_Text := 'Heating runtime health observer disabled';

L_Healthy := TRUE;
L_Degraded := FALSE;
L_Critical := FALSE;

IF NOT VI_Enable THEN
    RETURN;
END_IF;

// ======================================================
// SEQUENCING HEALTH
// ======================================================
VO_Sequencing_Healthy :=
    VI_Bridge.DHW_Before_Heating_Valid AND
    VI_Bridge.Diagnostics_After_Publication_Valid AND
    VI_Bridge.Output_Projection_Last_Valid AND
    VI_Sequencing_Synchronized;

IF NOT VO_Sequencing_Healthy THEN
    L_Healthy := FALSE;
    L_Degraded := TRUE;
END_IF;

// ======================================================
// OWNERSHIP HEALTH
// ======================================================
VO_Ownership_Healthy :=
    VI_Bridge.Runtime_Ownership_Valid AND
    VI_Bridge.Diagnostics_Ownership_Valid AND
    VI_Bridge.Explainability_Ownership_Valid AND
    VI_Bridge.OpenTherm_Ownership_Valid AND
    VI_Bridge.Cascade_Ownership_Valid AND
    VI_Bridge.Safety_Ownership_Valid AND
    VI_Ownership_Synchronized;

IF NOT VO_Ownership_Healthy THEN
    L_Healthy := FALSE;
    L_Critical := TRUE;
END_IF;

// ======================================================
// SYNCHRONIZATION HEALTH
// ======================================================
VO_Synchronization_Healthy :=
    VI_Synchronized AND
    VI_Phase_Synchronized;

IF NOT VO_Synchronization_Healthy THEN
    L_Healthy := FALSE;
    L_Degraded := TRUE;
END_IF;

// ======================================================
// CONTEXT HEALTH
// ======================================================
IF VI_Context.Runtime_Fault THEN
    L_Healthy := FALSE;
    L_Critical := TRUE;
END_IF;

IF NOT VI_Bridge.Runtime_Migration_Allowed THEN
    L_Healthy := FALSE;
    L_Degraded := TRUE;
END_IF;

// ======================================================
// FINAL HEALTH
// ======================================================
VO_Runtime_Healthy :=
    L_Healthy AND
    NOT L_Degraded AND
    NOT L_Critical;

VO_Runtime_Degraded :=
    L_Degraded AND
    NOT L_Critical;

VO_Runtime_Critical := L_Critical;

// ======================================================
// STATUS
// ======================================================
IF L_Critical THEN
    VO_Status_Code := 900;
    VO_Status_Text := 'Heating runtime orchestration critical';

ELSIF L_Degraded THEN
    VO_Status_Code := 200;
    VO_Status_Text := 'Heating runtime orchestration degraded';

ELSE
    VO_Status_Code := 1;
    VO_Status_Text := 'Heating runtime orchestration healthy';
END_IF;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_Health_Observer <<<
