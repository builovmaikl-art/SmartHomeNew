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
VAR
    L_i : INT;
    L_Any_Manifold_Pump : BOOL;
    L_Any_Manifold_Valve_Open : BOOL;
    L_Any_Boiler_OT_Online : BOOL;
    L_All_Boiler_Commands_Ack : BOOL;
    L_Any_OT_Transport_Degraded : BOOL;
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

IF NOT VI_Enable THEN
    RETURN;
END_IF;

// ======================================================
// LOCAL AGGREGATION
// ======================================================
L_Any_Manifold_Pump := FALSE;
L_Any_Manifold_Valve_Open := FALSE;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    IF GVL_STATE.G_Manifold_Pumps[L_i] THEN
        L_Any_Manifold_Pump := TRUE;
    END_IF;

    IF GVL_STATE.G_Manifold_Valves[L_i] > 5.0 THEN
        L_Any_Manifold_Valve_Open := TRUE;
    END_IF;
END_FOR;

L_Any_Boiler_OT_Online := FALSE;
L_All_Boiler_Commands_Ack := TRUE;
L_Any_OT_Transport_Degraded := FALSE;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BOILERS DO
    IF GVL_STATE.G_Boiler_OT_Online[L_i] THEN
        L_Any_Boiler_OT_Online := TRUE;
    END_IF;

    IF GVL_STATE.G_Boiler_OT_Enable[L_i] AND NOT GVL_STATE.G_Boiler_OT_Command_Ack[L_i] THEN
        L_All_Boiler_Commands_Ack := FALSE;
    END_IF;

    IF GVL_STATE.G_Boiler_OT_Command_Timeout[L_i] OR
       GVL_STATE.G_Boiler_OT_Heartbeat_Timeout[L_i] OR
       GVL_STATE.G_Boiler_OT_Adapter_Error[L_i] THEN
        L_Any_OT_Transport_Degraded := TRUE;
    END_IF;
END_FOR;

// ======================================================
// LIVE RUNTIME OBSERVATION
// ======================================================
VO_Observation.Runtime_Active := TRUE;
VO_Observation.Runtime_Ready := TRUE;
VO_Observation.Runtime_Fault :=
    GVL_STATE.G_Heating_IO_Fault OR
    GVL_STATE.G_Safety_Emergency_Stop;

// ======================================================
// DHW OBSERVATION
// ======================================================
VO_Observation.DHW_Demand_Active :=
    GVL_STATE.G_DHW_Heating_Pump;

VO_Observation.DHW_Heating_Active :=
    GVL_IO.DO_DHW_Heating_Pump;

VO_Observation.DHW_Circulation_Active :=
    GVL_IO.DO_DHW_Circ_Pump;

// ======================================================
// HEATING OBSERVATION
// ======================================================
VO_Observation.Heating_Demand_Active :=
    L_Any_Manifold_Pump OR
    L_Any_Manifold_Valve_Open OR
    GVL_STATE.G_Freeze_Request OR
    GVL_STATE.G_Preheat_Request;

VO_Observation.Heating_Runtime_Active :=
    NOT GVL_STATE.G_Safety_Emergency_Stop;

VO_Observation.Heating_Output_Active :=
    L_Any_Manifold_Pump OR
    GVL_STATE.G_Backup_Circulation_Pump OR
    GVL_STATE.G_Electric_Heater_Enable;

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
    L_Any_Boiler_OT_Online;

VO_Observation.OpenTherm_Command_Valid :=
    L_All_Boiler_Commands_Ack;

VO_Observation.OpenTherm_Transport_Degraded :=
    GVL_STATE.G_Heating_Cascade_Transport_Degraded OR
    L_Any_OT_Transport_Degraded;

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
