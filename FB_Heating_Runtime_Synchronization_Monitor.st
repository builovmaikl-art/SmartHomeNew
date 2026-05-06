// ==============================================================================
// Heating runtime synchronization monitor
// Read-only orchestration synchronization layer.
// DOES NOT own runtime.
// DOES NOT own heating logic.
// DOES NOT own diagnostics.
// DOES NOT own OpenTherm transport.
// DOES NOT migrate runtime ownership.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Runtime_Synchronization_Monitor
VAR_INPUT
    VI_Enable : BOOL;
    VI_Context : ST_Heating_Runtime_Context;
    VI_Bridge : ST_Heating_Runtime_Integration_Bridge;
END_VAR
VAR_OUTPUT
    VO_Synchronized : BOOL;
    VO_Phase_Synchronized : BOOL;
    VO_Ownership_Synchronized : BOOL;
    VO_Sequencing_Synchronized : BOOL;

    VO_Status_Code : UINT;
    VO_Status_Text : STRING(128);
END_VAR
VAR
    L_Phase_Valid : BOOL;
    L_Ownership_Valid : BOOL;
    L_Sequencing_Valid : BOOL;
END_VAR

// ======================================================
// DEFAULTS
// ======================================================
VO_Synchronized := FALSE;
VO_Phase_Synchronized := FALSE;
VO_Ownership_Synchronized := FALSE;
VO_Sequencing_Synchronized := FALSE;

VO_Status_Code := 0;
VO_Status_Text := 'Heating runtime synchronization monitor disabled';

L_Phase_Valid := TRUE;
L_Ownership_Valid := TRUE;
L_Sequencing_Valid := TRUE;

IF NOT VI_Enable THEN
    RETURN;
END_IF;

// ======================================================
// PHASE SYNCHRONIZATION
// ======================================================
IF VI_Context.Current_Phase <> VI_Bridge.Current_Phase THEN
    L_Phase_Valid := FALSE;
END_IF;

IF NOT VI_Bridge.Runtime_Synchronized THEN
    L_Phase_Valid := FALSE;
END_IF;

// ======================================================
// OWNERSHIP SYNCHRONIZATION
// ======================================================
IF NOT VI_Bridge.Runtime_Ownership_Valid THEN
    L_Ownership_Valid := FALSE;
END_IF;

IF NOT VI_Bridge.Diagnostics_Ownership_Valid THEN
    L_Ownership_Valid := FALSE;
END_IF;

IF NOT VI_Bridge.Explainability_Ownership_Valid THEN
    L_Ownership_Valid := FALSE;
END_IF;

IF NOT VI_Bridge.OpenTherm_Ownership_Valid THEN
    L_Ownership_Valid := FALSE;
END_IF;

IF NOT VI_Bridge.Cascade_Ownership_Valid THEN
    L_Ownership_Valid := FALSE;
END_IF;

IF NOT VI_Bridge.Safety_Ownership_Valid THEN
    L_Ownership_Valid := FALSE;
END_IF;

// ======================================================
// SEQUENCING SYNCHRONIZATION
// ======================================================
IF NOT VI_Bridge.DHW_Before_Heating_Valid THEN
    L_Sequencing_Valid := FALSE;
END_IF;

IF NOT VI_Bridge.Diagnostics_After_Publication_Valid THEN
    L_Sequencing_Valid := FALSE;
END_IF;

IF NOT VI_Bridge.Output_Projection_Last_Valid THEN
    L_Sequencing_Valid := FALSE;
END_IF;

// ======================================================
// OUTPUTS
// ======================================================
VO_Phase_Synchronized := L_Phase_Valid;
VO_Ownership_Synchronized := L_Ownership_Valid;
VO_Sequencing_Synchronized := L_Sequencing_Valid;

VO_Synchronized :=
    L_Phase_Valid AND
    L_Ownership_Valid AND
    L_Sequencing_Valid AND
    VI_Bridge.Runtime_Migration_Allowed;

// ======================================================
// STATUS
// ======================================================
IF NOT L_Phase_Valid THEN
    VO_Status_Code := 100;
    VO_Status_Text := 'Heating runtime phase synchronization failed';

ELSIF NOT L_Ownership_Valid THEN
    VO_Status_Code := 200;
    VO_Status_Text := 'Heating runtime ownership synchronization failed';

ELSIF NOT L_Sequencing_Valid THEN
    VO_Status_Code := 300;
    VO_Status_Text := 'Heating runtime sequencing synchronization failed';

ELSIF NOT VI_Bridge.Runtime_Migration_Allowed THEN
    VO_Status_Code := 400;
    VO_Status_Text := 'Heating runtime migration not allowed';

ELSE
    VO_Status_Code := 1;
    VO_Status_Text := 'Heating runtime synchronization valid';
END_IF;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_Synchronization_Monitor <<<
