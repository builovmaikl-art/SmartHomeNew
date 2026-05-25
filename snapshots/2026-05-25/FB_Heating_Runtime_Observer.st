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
VO_Observation.Runtime_Active := FALSE;
VO_Observation.Runtime_Ready := FALSE;
VO_Observation.Runtime_Fault := FALSE;
VO_Observation.Current_Phase := E_Heating_Runtime_Phase.HRP_DISABLED;

VO_Observation.DHW_Demand_Active := FALSE;
VO_Observation.DHW_Heating_Active := FALSE;
VO_Observation.DHW_Circulation_Active := FALSE;

VO_Observation.Heating_Demand_Active := FALSE;
VO_Observation.Heating_Runtime_Active := FALSE;
VO_Observation.Heating_Output_Active := FALSE;

VO_Observation.Cascade_Available := FALSE;
VO_Observation.Cascade_Degraded := FALSE;
VO_Observation.Cascade_Active_Boilers := 0;
VO_Observation.Cascade_Available_Boilers := 0;

VO_Observation.OpenTherm_Online := FALSE;
VO_Observation.OpenTherm_Command_Valid := FALSE;
VO_Observation.OpenTherm_Transport_Degraded := FALSE;

VO_Observation.Diagnostics_Active := FALSE;
VO_Observation.Explainability_Active := FALSE;

VO_Observation.DHW_Before_Heating_Observed := FALSE;
VO_Observation.Diagnostics_After_Publication_Observed := FALSE;
VO_Observation.Output_Projection_Last_Observed := FALSE;

VO_Observation.Runtime_Ownership_Valid := TRUE;
VO_Observation.Diagnostics_Ownership_Valid := TRUE;
VO_Observation.OpenTherm_Ownership_Valid := TRUE;
VO_Observation.Cascade_Ownership_Valid := TRUE;
VO_Observation.Safety_Ownership_Valid := TRUE;

VO_Observation.Observation_Status_Code := 0;
VO_Observation.Observation_Status_Text := 'Heating runtime observer disabled';

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
VO_Observation.Runtime_Active := VI_Runtime_Context.Runtime_Enabled;
VO_Observation.Runtime_Ready := VI_Runtime_Context.Runtime_Ready;
VO_Observation.Runtime_Fault := VI_Runtime_Context.Runtime_Fault;
VO_Observation.Current_Phase := VI_Runtime_Context.Current_Phase;

VO_Observation.Diagnostics_Active := VI_Diagnostics_Valid;
VO_Observation.Explainability_Active := VI_Runtime_Context.Explainability_Isolation_Valid;

VO_Observation.DHW_Before_Heating_Observed :=
    VI_Runtime_Context.DHW_Before_Heating_Valid;

VO_Observation.Diagnostics_After_Publication_Observed :=
    VI_Runtime_Context.State_Publication_Before_Diagnostics_Valid;

VO_Observation.Output_Projection_Last_Observed :=
    VI_Runtime_Context.Output_Projection_Last_Valid;

VO_Observation.Runtime_Ownership_Valid := TRUE;
VO_Observation.Diagnostics_Ownership_Valid :=
    VI_Runtime_Context.Diagnostics_Isolation_Valid;

VO_Observation.OpenTherm_Ownership_Valid :=
    VI_Runtime_Context.OpenTherm_Ownership_Valid;

VO_Observation.Cascade_Ownership_Valid :=
    VI_Runtime_Context.Cascade_Ownership_Valid;

VO_Observation.Safety_Ownership_Valid :=
    VI_Runtime_Context.Safety_Isolation_Valid;

// These domain-specific runtime values remain intentionally FALSE/0 here.
// They must be populated only by finalized publication contracts, not by internal runtime scans.
VO_Observation.DHW_Demand_Active := FALSE;
VO_Observation.DHW_Heating_Active := FALSE;
VO_Observation.DHW_Circulation_Active := FALSE;
VO_Observation.Heating_Demand_Active := FALSE;
VO_Observation.Heating_Runtime_Active := FALSE;
VO_Observation.Heating_Output_Active := FALSE;
VO_Observation.Cascade_Available := FALSE;
VO_Observation.Cascade_Degraded := FALSE;
VO_Observation.Cascade_Active_Boilers := 0;
VO_Observation.Cascade_Available_Boilers := 0;
VO_Observation.OpenTherm_Online := FALSE;
VO_Observation.OpenTherm_Command_Valid := FALSE;
VO_Observation.OpenTherm_Transport_Degraded := FALSE;

// ======================================================
// STATUS
// ======================================================
IF VI_Runtime_Context.Runtime_Fault THEN
    VO_Observation.Observation_Status_Code := 900;
    VO_Observation.Observation_Status_Text := 'Heating runtime observer detected runtime fault';

ELSIF NOT VI_Diagnostics_Valid THEN
    VO_Observation.Observation_Status_Code := 200;
    VO_Observation.Observation_Status_Text := 'Heating runtime diagnostics publication invalid';

ELSE
    VO_Observation.Observation_Status_Code := 1;
    VO_Observation.Observation_Status_Text := 'Heating runtime observer nominal';
END_IF;

VO_Observer_Ready := TRUE;
VO_Observer_Fault := FALSE;

VO_Status_Code := VO_Observation.Observation_Status_Code;
VO_Status_Text := VO_Observation.Observation_Status_Text;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_Observer <<<
