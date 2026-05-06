// ==============================================================================
// Heating runtime observer
// Minimal observer-only runtime attachment.
// Read-only.
// Governance-locked.
// Finalized-state observation only.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Runtime_Observer
VAR_INPUT
    VI_Enable : BOOL;
    VI_Runtime_Context : ST_Heating_Runtime_Context;
    VI_Diagnostics_Valid : BOOL;
END_VAR
VAR_OUTPUT
    VO_Observation : ST_Heating_Runtime_Observation;

    VO_Observer_Ready : BOOL;
    VO_Observer_Fault : BOOL;
    VO_Status_Code : UINT;
    VO_Status_Text : STRING(128);
END_VAR

// ======================================================
// DEFAULTS
// ======================================================
VO_Observation.Runtime_Visible := FALSE;
VO_Observation.Diagnostics_Visible := FALSE;
VO_Observation.OT_Visible := FALSE;
VO_Observation.Cascade_Visible := FALSE;

VO_Observation.Runtime_Ready := FALSE;
VO_Observation.Runtime_Fault := FALSE;
VO_Observation.Diagnostics_Valid := FALSE;

VO_Observation.Current_Phase := E_Heating_Runtime_Phase.HRP_DISABLED;

VO_Observation.Sequencing_Visible := FALSE;
VO_Observation.Ownership_Visible := FALSE;
VO_Observation.Synchronization_Visible := FALSE;

VO_Observation.Status_Code := 0;
VO_Observation.Status_Text := 'Heating runtime observer disabled';

VO_Observer_Ready := FALSE;
VO_Observer_Fault := FALSE;
VO_Status_Code := 0;
VO_Status_Text := 'Heating runtime observer disabled';

IF NOT VI_Enable THEN
    RETURN;
END_IF;

// ======================================================
// FINALIZED-STATE OBSERVATION ONLY
// ======================================================
VO_Observation.Runtime_Visible := TRUE;
VO_Observation.Diagnostics_Visible := TRUE;
VO_Observation.OT_Visible := TRUE;
VO_Observation.Cascade_Visible := TRUE;

VO_Observation.Runtime_Ready :=
    VI_Runtime_Context.Runtime_Ready;

VO_Observation.Runtime_Fault :=
    VI_Runtime_Context.Runtime_Fault;

VO_Observation.Diagnostics_Valid :=
    VI_Diagnostics_Valid;

VO_Observation.Current_Phase :=
    VI_Runtime_Context.Current_Phase;

VO_Observation.Sequencing_Visible :=
    VI_Runtime_Context.DHW_Before_Heating_Valid;

VO_Observation.Ownership_Visible :=
    VI_Runtime_Context.Cascade_Ownership_Valid AND
    VI_Runtime_Context.OpenTherm_Ownership_Valid;

VO_Observation.Synchronization_Visible :=
    VI_Runtime_Context.State_Publication_Before_Diagnostics_Valid;

// ======================================================
// STATUS
// ======================================================
IF VI_Runtime_Context.Runtime_Fault THEN
    VO_Observation.Status_Code := 900;
    VO_Observation.Status_Text := 'Heating runtime observer detected runtime fault';

ELSIF NOT VI_Diagnostics_Valid THEN
    VO_Observation.Status_Code := 200;
    VO_Observation.Status_Text := 'Heating runtime diagnostics publication invalid';

ELSE
    VO_Observation.Status_Code := 1;
    VO_Observation.Status_Text := 'Heating runtime observer nominal';
END_IF;

VO_Observer_Ready := TRUE;
VO_Observer_Fault := FALSE;

VO_Status_Code := VO_Observation.Status_Code;
VO_Status_Text := VO_Observation.Status_Text;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_Observer <<<
