// ==============================================================================
// Heating root-cause inference engine
// Internal diagnostics core.
// Does NOT own explainability publication or runtime control.
// ==============================================================================
FUNCTION_BLOCK FB_Diagnostics_RootCause
VAR_INPUT
    // Safety / global blocking
    VI_Emergency_Stop : BOOL;
    VI_Gas_Safety : BOOL;
    VI_IO_Failsafe : BOOL;

    // Modern cascade semantic state
    VI_Cascade_Available : BOOL;
    VI_Cascade_Degraded : BOOL;
    VI_Cascade_Partial_Capacity : BOOL;
    VI_Cascade_No_Flame : BOOL;
    VI_Cascade_Transport_Degraded : BOOL;
    VI_Cascade_Ignition_Timeout : BOOL;
    VI_Cascade_Active_Boilers : UINT;
    VI_Cascade_Available_Boilers : UINT;

    // Boiler / OpenTherm state
    VI_Boiler_OT_Online : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF BOOL;
    VI_Boiler_Error : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF BOOL;
    VI_Boiler_Flame : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF BOOL;
    VI_Boiler_OT_Command_Timeout : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF BOOL;
    VI_Boiler_OT_Heartbeat_Timeout : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF BOOL;
    VI_Boiler_OT_Adapter_Error : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF BOOL;

    // Hydraulics
    VI_Manifold_Pumps : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    VI_Manifold_Valves : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL;

    // Sensors / thermal transfer
    VI_Sensor_Error : BOOL;
    VI_Supply_Temps : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL;
    VI_Target_Supply : REAL;
    VI_Demand_Map : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
END_VAR

VAR_OUTPUT
    VO_RootCause : E_Heating_RootCause;
    VO_Confidence : REAL;
    VO_Error_Score : REAL;
    VO_Reason_Code : INT;
    VO_Reason_Text : STRING(128);
END_VAR

VAR
    L_i : INT;
    L_AnyBoilerOnline : BOOL;
    L_AnyBoilerError : BOOL;
    L_AnyFlame : BOOL;
    L_AnyCommandTimeout : BOOL;
    L_AnyHeartbeatTimeout : BOOL;
    L_AnyAdapterError : BOOL;
    L_AnyDemand : BOOL;
    L_AnyPumpOn : BOOL;
    L_AnyValveOpen : BOOL;
    L_LowSupply : BOOL;
    L_CascadeSemanticKnown : BOOL;
END_VAR

// ======================================================
// DEFAULTS
// ======================================================
VO_RootCause := E_Heating_RootCause.RC_NONE;
VO_Confidence := 1.0;
VO_Error_Score := 0.0;
VO_Reason_Code := 0;
VO_Reason_Text := 'Heating inference OK';

// ======================================================
// SAFETY / GLOBAL BLOCKS
// ======================================================
IF VI_Emergency_Stop THEN
    VO_RootCause := E_Heating_RootCause.RC_EMERGENCY_STOP;
    VO_Confidence := 1.0;
    VO_Error_Score := 1.0;
    VO_Reason_Code := 10;
    VO_Reason_Text := 'Emergency stop active';
    RETURN;
END_IF;

IF VI_Gas_Safety THEN
    VO_RootCause := E_Heating_RootCause.RC_GAS_SAFETY;
    VO_Confidence := 1.0;
    VO_Error_Score := 1.0;
    VO_Reason_Code := 20;
    VO_Reason_Text := 'Gas safety active';
    RETURN;
END_IF;

IF VI_IO_Failsafe THEN
    VO_RootCause := E_Heating_RootCause.RC_IO_OFFLINE;
    VO_Confidence := 1.0;
    VO_Error_Score := 1.0;
    VO_Reason_Code := 30;
    VO_Reason_Text := 'Heating IO failsafe active';
    RETURN;
END_IF;

// ======================================================
// AGGREGATE LEGACY / LOW-LEVEL FLAGS
// ======================================================
L_AnyBoilerOnline := FALSE;
L_AnyBoilerError := FALSE;
L_AnyFlame := FALSE;
L_AnyCommandTimeout := FALSE;
L_AnyHeartbeatTimeout := FALSE;
L_AnyAdapterError := FALSE;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BOILERS DO
    IF VI_Boiler_OT_Online[L_i] THEN
        L_AnyBoilerOnline := TRUE;
    END_IF;

    IF VI_Boiler_Error[L_i] THEN
        L_AnyBoilerError := TRUE;
    END_IF;

    IF VI_Boiler_Flame[L_i] THEN
        L_AnyFlame := TRUE;
    END_IF;

    IF VI_Boiler_OT_Command_Timeout[L_i] THEN
        L_AnyCommandTimeout := TRUE;
    END_IF;

    IF VI_Boiler_OT_Heartbeat_Timeout[L_i] THEN
        L_AnyHeartbeatTimeout := TRUE;
    END_IF;

    IF VI_Boiler_OT_Adapter_Error[L_i] THEN
        L_AnyAdapterError := TRUE;
    END_IF;
END_FOR;

L_AnyDemand := FALSE;
L_AnyPumpOn := FALSE;
L_AnyValveOpen := FALSE;
L_LowSupply := FALSE;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    IF VI_Demand_Map[L_i] THEN
        L_AnyDemand := TRUE;
    END_IF;

    IF VI_Manifold_Pumps[L_i] THEN
        L_AnyPumpOn := TRUE;
    END_IF;

    IF VI_Manifold_Valves[L_i] > 5.0 THEN
        L_AnyValveOpen := TRUE;
    END_IF;

    IF VI_Demand_Map[L_i] AND (VI_Supply_Temps[L_i] < (VI_Target_Supply - 2.0)) THEN
        L_LowSupply := TRUE;
    END_IF;
END_FOR;

L_CascadeSemanticKnown :=
    VI_Cascade_Available OR
    VI_Cascade_Degraded OR
    VI_Cascade_Partial_Capacity OR
    VI_Cascade_No_Flame OR
    VI_Cascade_Transport_Degraded OR
    VI_Cascade_Ignition_Timeout OR
    (VI_Cascade_Active_Boilers > 0) OR
    (VI_Cascade_Available_Boilers > 0);

// ======================================================
// MODERN CASCADE / OPENTHERM SEMANTICS
// ======================================================
IF L_CascadeSemanticKnown THEN

    IF NOT VI_Cascade_Available THEN
        VO_RootCause := E_Heating_RootCause.RC_BOILER_OFFLINE;
        VO_Confidence := 0.95;
        VO_Error_Score := 0.95;
        VO_Reason_Code := 100;
        VO_Reason_Text := 'Heating cascade unavailable';
        RETURN;
    END_IF;

    IF VI_Cascade_Transport_Degraded THEN
        IF L_AnyHeartbeatTimeout THEN
            VO_RootCause := E_Heating_RootCause.RC_IO_OFFLINE;
            VO_Confidence := 0.90;
            VO_Error_Score := 0.90;
            VO_Reason_Code := 210;
            VO_Reason_Text := 'OpenTherm heartbeat timeout';
            RETURN;
        END_IF;

        IF L_AnyCommandTimeout THEN
            VO_RootCause := E_Heating_RootCause.RC_IO_OFFLINE;
            VO_Confidence := 0.85;
            VO_Error_Score := 0.85;
            VO_Reason_Code := 220;
            VO_Reason_Text := 'OpenTherm command ACK timeout';
            RETURN;
        END_IF;

        IF L_AnyAdapterError THEN
            VO_RootCause := E_Heating_RootCause.RC_IO_OFFLINE;
            VO_Confidence := 0.85;
            VO_Error_Score := 0.85;
            VO_Reason_Code := 230;
            VO_Reason_Text := 'OpenTherm adapter error';
            RETURN;
        END_IF;

        VO_RootCause := E_Heating_RootCause.RC_IO_OFFLINE;
        VO_Confidence := 0.75;
        VO_Error_Score := 0.75;
        VO_Reason_Code := 200;
        VO_Reason_Text := 'OpenTherm transport degraded';
        RETURN;
    END_IF;

    IF VI_Cascade_Ignition_Timeout THEN
        VO_RootCause := E_Heating_RootCause.RC_NO_FLAME;
        VO_Confidence := 0.90;
        VO_Error_Score := 0.90;
        VO_Reason_Code := 300;
        VO_Reason_Text := 'Boiler ignition timeout';
        RETURN;
    END_IF;

    IF VI_Cascade_No_Flame THEN
        VO_RootCause := E_Heating_RootCause.RC_NO_FLAME;
        VO_Confidence := 0.80;
        VO_Error_Score := 0.80;
        VO_Reason_Code := 310;
        VO_Reason_Text := 'Cascade active but no flame';
        RETURN;
    END_IF;

    IF VI_Cascade_Partial_Capacity THEN
        VO_RootCause := E_Heating_RootCause.RC_LOW_SUPPLY_TEMP;
        VO_Confidence := 0.60;
        VO_Error_Score := 0.40;
        VO_Reason_Code := 500;
        VO_Reason_Text := 'Partial cascade capacity';
        RETURN;
    END_IF;
END_IF;

// ======================================================
// LEGACY BOILER / TRANSPORT FALLBACK
// ======================================================
IF NOT L_AnyBoilerOnline THEN
    VO_RootCause := E_Heating_RootCause.RC_BOILER_OFFLINE;
    VO_Confidence := 0.90;
    VO_Error_Score := 0.90;
    VO_Reason_Code := 110;
    VO_Reason_Text := 'No boiler online';
    RETURN;
END_IF;

IF L_AnyBoilerError THEN
    VO_RootCause := E_Heating_RootCause.RC_BOILER_ERROR;
    VO_Confidence := 0.90;
    VO_Error_Score := 0.90;
    VO_Reason_Code := 120;
    VO_Reason_Text := 'Boiler error active';
    RETURN;
END_IF;

IF L_AnyDemand AND NOT L_AnyFlame THEN
    VO_RootCause := E_Heating_RootCause.RC_NO_FLAME;
    VO_Confidence := 0.80;
    VO_Error_Score := 0.80;
    VO_Reason_Code := 130;
    VO_Reason_Text := 'Demand active but no flame';
    RETURN;
END_IF;

// ======================================================
// HYDRAULICS
// ======================================================
IF L_AnyDemand THEN
    IF NOT L_AnyPumpOn THEN
        VO_RootCause := E_Heating_RootCause.RC_PUMP_FAILURE;
        VO_Confidence := 0.80;
        VO_Error_Score := 0.80;
        VO_Reason_Code := 400;
        VO_Reason_Text := 'Demand active but manifold pumps are off';
        RETURN;
    END_IF;

    IF NOT L_AnyValveOpen THEN
        VO_RootCause := E_Heating_RootCause.RC_VALVES_CLOSED;
        VO_Confidence := 0.80;
        VO_Error_Score := 0.80;
        VO_Reason_Code := 410;
        VO_Reason_Text := 'Demand active but manifold valves are closed';
        RETURN;
    END_IF;
END_IF;

// ======================================================
// THERMAL TRANSFER
// ======================================================
IF L_AnyDemand AND L_LowSupply THEN
    VO_RootCause := E_Heating_RootCause.RC_NO_HEAT_TRANSFER;
    VO_Confidence := 0.70;
    VO_Error_Score := 0.70;
    VO_Reason_Code := 420;
    VO_Reason_Text := 'Supply temperature below target under demand';
    RETURN;
END_IF;

// ======================================================
// SENSORS
// ======================================================
IF VI_Sensor_Error THEN
    VO_RootCause := E_Heating_RootCause.RC_SENSOR_ERROR;
    VO_Confidence := 0.70;
    VO_Error_Score := 0.70;
    VO_Reason_Code := 450;
    VO_Reason_Text := 'Heating sensor error active';
    RETURN;
END_IF;

// ======================================================
// NORMAL
// ======================================================
VO_RootCause := E_Heating_RootCause.RC_NONE;
VO_Confidence := 1.0;
VO_Error_Score := 0.0;
VO_Reason_Code := 0;
VO_Reason_Text := 'Heating inference OK';

END_FUNCTION_BLOCK
