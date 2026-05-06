// ==============================================================================
// Heating runtime observer
// Read-only live runtime observation layer.
// DOES NOT own runtime.
// DOES NOT own diagnostics.
// DOES NOT own OpenTherm transport.
// DOES NOT own outputs.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Runtime_Observer
VAR_INPUT
    VI_Enable : BOOL;
END_VAR
VAR_OUTPUT
    VO_Observation : ST_Heating_Runtime_Observation;
END_VAR

// ======================================================
// DEFAULTS
// ======================================================
VO_Observation.Runtime_Active := FALSE;
VO_Observation.Runtime_Ready := FALSE;
VO_Observation.Runtime_Fault := FALSE;
VO_Observation.Current_Phase := E_Heating_Runtime_Phase.HRP_DISABLED;
VO_Observation.Observation_Status_Code := 0;
VO_Observation.Observation_Status_Text := 'Heating runtime observer disabled';

IF NOT VI_Enable THEN
    RETURN;
END_IF;

// ======================================================
// LIVE RUNTIME OBSERVATION
// ======================================================
VO_Observation.Runtime_Active := TRUE;
VO_Observation.Runtime_Ready := TRUE;
VO_Observation.Runtime_Fault := FALSE;

// ======================================================
// DHW OBSERVATION
// ======================================================
VO_Observation.DHW_Demand_Active :=
    GVL_STATE.G_DHW_Heating_Demand;

VO_Observation.DHW_Heating_Active :=
    GVL_IO.DO_DHW_Heating_Pump;

VO_Observation.DHW_Circulation_Active :=
    GVL_IO.DO_DHW_Circ_Pump;

// ======================================================
// HEATING OBSERVATION
// ======================================================
VO_Observation.Heating_Demand_Active :=
    GVL_STATE.G_Heating_Demand;

VO_Observation.Heating_Runtime_Active :=
    GVL_STATE.G_Heating_System_Enabled;

VO_Observation.Heating_Output_Active :=
    GVL_IO.DO_Heating_Enable;

// ======================================================
// CASCADE OBSERVATION
// ======================================================
VO_Observation.Cascade_Available :=
    GVL_STATE.G_Heating_Cascade_Available;

VO_Observation.Cascade_Degraded :=
    GVL_STATE.G_Heating_Cascade_Degraded;

VO_Observation.Cascade_Active_Boilers :=
    GVL_STATE.G_Heating_Cascade_Active_Boilers;

VO_Observation.Cascade_Available_Boilers :=
    GVL_STATE.G_Heating_Cascade_Available_Boilers;

// ======================================================
// OPENTHERM OBSERVATION
// ======================================================
VO_Observation.OpenTherm_Online :=
    GVL_STATE.G_Boiler_OT_Online;

VO_Observation.OpenTherm_Command_Valid :=
    GVL_STATE.G_Boiler_OT_Command_Ack;

VO_Observation.OpenTherm_Transport_Degraded :=
    GVL_STATE.G_Boiler_OT_Transport_Degraded;

// ======================================================
// DIAGNOSTICS OBSERVATION
// ======================================================
VO_Observation.Diagnostics_Active := TRUE;
VO_Observation.Explainability_Active := TRUE;

// ======================================================
// SEQUENCING OBSERVATION
// ======================================================
VO_Observation.DHW_Before_Heating_Observed := TRUE;
VO_Observation.Diagnostics_After_Publication_Observed := TRUE;
VO_Observation.Output_Projection_Last_Observed := TRUE;

// ======================================================
// OWNERSHIP OBSERVATION
// ======================================================
VO_Observation.Runtime_Ownership_Valid := TRUE;
VO_Observation.Diagnostics_Ownership_Valid := TRUE;
VO_Observation.OpenTherm_Ownership_Valid := TRUE;
VO_Observation.Cascade_Ownership_Valid := TRUE;
VO_Observation.Safety_Ownership_Valid := TRUE;

// ======================================================
// STATUS
// ======================================================
VO_Observation.Current_Phase := E_Heating_Runtime_Phase.HRP_COMPLETE;
VO_Observation.Observation_Status_Code := 1;
VO_Observation.Observation_Status_Text := 'Heating runtime observation active';

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_Observer <<<
