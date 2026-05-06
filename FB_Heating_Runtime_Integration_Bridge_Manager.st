// ==============================================================================
// Heating runtime integration bridge manager
// Read-only orchestration integration layer.
// DOES NOT own runtime.
// DOES NOT own heating logic.
// DOES NOT own diagnostics.
// DOES NOT own OpenTherm transport.
// DOES NOT connect orchestration to live runtime yet.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Runtime_Integration_Bridge_Manager
VAR_INPUT
    VI_Enable : BOOL;
    VI_Runtime_Context : ST_Heating_Runtime_Context;
    VI_Contract_Valid : BOOL;
END_VAR
VAR_OUTPUT
    VO_Bridge : ST_Heating_Runtime_Integration_Bridge;

    VO_Bridge_Ready : BOOL;
    VO_Bridge_Fault : BOOL;
    VO_Bridge_Status_Code : UINT;
    VO_Bridge_Status_Text : STRING(128);
END_VAR

// ======================================================
// DEFAULTS
// ======================================================
VO_Bridge.Shell_Ready := FALSE;
VO_Bridge.Shell_Fault := FALSE;
VO_Bridge.Shell_Contract_Valid := FALSE;

VO_Bridge.Allow_DHW_Integration := FALSE;
VO_Bridge.Allow_Heating_Integration := FALSE;
VO_Bridge.Allow_Diagnostics_Integration := FALSE;
VO_Bridge.Allow_Output_Projection_Integration := FALSE;

VO_Bridge.Runtime_Ownership_Valid := TRUE;
VO_Bridge.Diagnostics_Ownership_Valid := TRUE;
VO_Bridge.Explainability_Ownership_Valid := TRUE;
VO_Bridge.OpenTherm_Ownership_Valid := TRUE;
VO_Bridge.Cascade_Ownership_Valid := TRUE;
VO_Bridge.Safety_Ownership_Valid := TRUE;

VO_Bridge.DHW_Before_Heating_Valid := TRUE;
VO_Bridge.Diagnostics_After_Publication_Valid := TRUE;
VO_Bridge.Output_Projection_Last_Valid := TRUE;

VO_Bridge.Runtime_Migration_Allowed := FALSE;
VO_Bridge.Runtime_Migration_Active := FALSE;
VO_Bridge.Runtime_Migration_Failed := FALSE;

VO_Bridge.Integration_Status_Code := 0;
VO_Bridge.Integration_Status_Text := 'Heating runtime bridge disabled';

VO_Bridge.Diagnostics_Visible := TRUE;
VO_Bridge.Explainability_Visible := TRUE;

VO_Bridge.Current_Phase := E_Heating_Runtime_Phase.HRP_DISABLED;
VO_Bridge.Runtime_Synchronized := FALSE;

VO_Bridge_Ready := FALSE;
VO_Bridge_Fault := FALSE;
VO_Bridge_Status_Code := 0;
VO_Bridge_Status_Text := 'Heating runtime bridge disabled';

IF NOT VI_Enable THEN
    RETURN;
END_IF;

// ======================================================
// SHELL STATE
// ======================================================
VO_Bridge.Shell_Ready := VI_Runtime_Context.Runtime_Ready;
VO_Bridge.Shell_Fault := VI_Runtime_Context.Runtime_Fault;
VO_Bridge.Shell_Contract_Valid := VI_Contract_Valid;

// ======================================================
// OWNERSHIP INTEGRITY
// ======================================================
VO_Bridge.Runtime_Ownership_Valid := TRUE;
VO_Bridge.Diagnostics_Ownership_Valid :=
    VI_Runtime_Context.Diagnostics_Isolation_Valid;

VO_Bridge.Explainability_Ownership_Valid :=
    VI_Runtime_Context.Explainability_Isolation_Valid;

VO_Bridge.OpenTherm_Ownership_Valid :=
    VI_Runtime_Context.OpenTherm_Ownership_Valid;

VO_Bridge.Cascade_Ownership_Valid :=
    VI_Runtime_Context.Cascade_Ownership_Valid;

VO_Bridge.Safety_Ownership_Valid :=
    VI_Runtime_Context.Safety_Isolation_Valid;

// ======================================================
// SEQUENCING INTEGRITY
// ======================================================
VO_Bridge.DHW_Before_Heating_Valid :=
    VI_Runtime_Context.DHW_Before_Heating_Valid;

VO_Bridge.Diagnostics_After_Publication_Valid :=
    VI_Runtime_Context.State_Publication_Before_Diagnostics_Valid;

VO_Bridge.Output_Projection_Last_Valid :=
    VI_Runtime_Context.Output_Projection_Last_Valid;

// ======================================================
// INTEGRATION SAFETY
// ======================================================
VO_Bridge.Allow_DHW_Integration :=
    VO_Bridge.DHW_Before_Heating_Valid;

VO_Bridge.Allow_Heating_Integration :=
    VO_Bridge.Runtime_Ownership_Valid AND
    VO_Bridge.Cascade_Ownership_Valid;

VO_Bridge.Allow_Diagnostics_Integration :=
    VO_Bridge.Diagnostics_Ownership_Valid AND
    VO_Bridge.Explainability_Ownership_Valid;

VO_Bridge.Allow_Output_Projection_Integration :=
    VO_Bridge.Output_Projection_Last_Valid;

// ======================================================
// MIGRATION SAFETY
// ======================================================
VO_Bridge.Runtime_Migration_Allowed :=
    VI_Contract_Valid AND
    NOT VI_Runtime_Context.Runtime_Fault AND
    VO_Bridge.Runtime_Ownership_Valid AND
    VO_Bridge.Diagnostics_Ownership_Valid AND
    VO_Bridge.Explainability_Ownership_Valid AND
    VO_Bridge.OpenTherm_Ownership_Valid AND
    VO_Bridge.Cascade_Ownership_Valid AND
    VO_Bridge.Safety_Ownership_Valid AND
    VO_Bridge.DHW_Before_Heating_Valid AND
    VO_Bridge.Diagnostics_After_Publication_Valid AND
    VO_Bridge.Output_Projection_Last_Valid;

VO_Bridge.Runtime_Migration_Active := FALSE;
VO_Bridge.Runtime_Migration_Failed := FALSE;

// ======================================================
// PHASE SYNCHRONIZATION
// ======================================================
VO_Bridge.Current_Phase := VI_Runtime_Context.Current_Phase;
VO_Bridge.Runtime_Synchronized := VI_Contract_Valid;

// ======================================================
// STATUS
// ======================================================
IF NOT VI_Contract_Valid THEN
    VO_Bridge.Integration_Status_Code := 100;
    VO_Bridge.Integration_Status_Text := 'Heating runtime contract invalid';

ELSIF VI_Runtime_Context.Runtime_Fault THEN
    VO_Bridge.Integration_Status_Code := 200;
    VO_Bridge.Integration_Status_Text := 'Heating runtime fault active';

ELSIF NOT VO_Bridge.Runtime_Migration_Allowed THEN
    VO_Bridge.Integration_Status_Code := 300;
    VO_Bridge.Integration_Status_Text := 'Heating runtime migration blocked';

ELSE
    VO_Bridge.Integration_Status_Code := 1;
    VO_Bridge.Integration_Status_Text := 'Heating runtime bridge ready';
END_IF;

VO_Bridge_Ready := VO_Bridge.Runtime_Migration_Allowed;
VO_Bridge_Fault :=
    NOT VI_Contract_Valid OR
    VI_Runtime_Context.Runtime_Fault;

VO_Bridge_Status_Code := VO_Bridge.Integration_Status_Code;
VO_Bridge_Status_Text := VO_Bridge.Integration_Status_Text;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_Integration_Bridge_Manager <<<
