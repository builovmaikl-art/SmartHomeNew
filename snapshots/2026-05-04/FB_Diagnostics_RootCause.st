FUNCTION_BLOCK FB_Diagnostics_RootCause
VAR_INPUT
    VI_Emergency_Stop : BOOL;
    VI_Gas_Safety : BOOL;
    VI_IO_Failsafe : BOOL;

    VI_Boiler_OT_Online : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF BOOL;
    VI_Boiler_Error : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF BOOL;
    VI_Boiler_Flame : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF BOOL;

    VI_Manifold_Pumps : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    VI_Manifold_Valves : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL;

    VI_Sensor_Error : BOOL;

    VI_Supply_Temps : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL;
    VI_Target_Supply : REAL;

    VI_Demand_Map : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
END_VAR

VAR_OUTPUT
    VO_RootCause : E_Heating_RootCause;
    VO_Confidence : REAL;
END_VAR

VAR
    L_i : INT;
    L_AnyBoilerOnline : BOOL;
    L_AnyBoilerError : BOOL;
    L_AnyFlame : BOOL;
    L_AnyDemand : BOOL;
    L_AnyPumpOn : BOOL;
    L_AnyValveOpen : BOOL;
    L_LowSupply : BOOL;
END_VAR

// --- Safety ---
IF VI_Emergency_Stop THEN
    VO_RootCause := E_Heating_RootCause.RC_EMERGENCY_STOP;
    VO_Confidence := 1.0;
    RETURN;
END_IF;

IF VI_Gas_Safety THEN
    VO_RootCause := E_Heating_RootCause.RC_GAS_SAFETY;
    VO_Confidence := 1.0;
    RETURN;
END_IF;

IF VI_IO_Failsafe THEN
    VO_RootCause := E_Heating_RootCause.RC_IO_OFFLINE;
    VO_Confidence := 1.0;
    RETURN;
END_IF;

// --- Aggregate flags ---
L_AnyBoilerOnline := FALSE;
L_AnyBoilerError := FALSE;
L_AnyFlame := FALSE;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BOILERS DO
    IF VI_Boiler_OT_Online[L_i] THEN L_AnyBoilerOnline := TRUE; END_IF;
    IF VI_Boiler_Error[L_i] THEN L_AnyBoilerError := TRUE; END_IF;
    IF VI_Boiler_Flame[L_i] THEN L_AnyFlame := TRUE; END_IF;
END_FOR;

L_AnyDemand := FALSE;
L_AnyPumpOn := FALSE;
L_AnyValveOpen := FALSE;
L_LowSupply := FALSE;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    IF VI_Demand_Map[L_i] THEN L_AnyDemand := TRUE; END_IF;
    IF VI_Manifold_Pumps[L_i] THEN L_AnyPumpOn := TRUE; END_IF;
    IF VI_Manifold_Valves[L_i] > 5.0 THEN L_AnyValveOpen := TRUE; END_IF;
    IF VI_Supply_Temps[L_i] < (VI_Target_Supply - 2.0) THEN L_LowSupply := TRUE; END_IF;
END_FOR;

// --- Boiler ---
IF NOT L_AnyBoilerOnline THEN
    VO_RootCause := E_Heating_RootCause.RC_BOILER_OFFLINE;
    VO_Confidence := 0.9;
    RETURN;
END_IF;

IF L_AnyBoilerError THEN
    VO_RootCause := E_Heating_RootCause.RC_BOILER_ERROR;
    VO_Confidence := 0.9;
    RETURN;
END_IF;

IF NOT L_AnyFlame THEN
    VO_RootCause := E_Heating_RootCause.RC_NO_FLAME;
    VO_Confidence := 0.8;
    RETURN;
END_IF;

// --- Hydraulics ---
IF L_AnyDemand THEN
    IF NOT L_AnyPumpOn THEN
        VO_RootCause := E_Heating_RootCause.RC_PUMP_FAILURE;
        VO_Confidence := 0.8;
        RETURN;
    END_IF;

    IF NOT L_AnyValveOpen THEN
        VO_RootCause := E_Heating_RootCause.RC_VALVES_CLOSED;
        VO_Confidence := 0.8;
        RETURN;
    END_IF;
END_IF;

// --- Thermal ---
IF L_AnyDemand AND L_LowSupply THEN
    VO_RootCause := E_Heating_RootCause.RC_NO_HEAT_TRANSFER;
    VO_Confidence := 0.7;
    RETURN;
END_IF;

// --- Sensors ---
IF VI_Sensor_Error THEN
    VO_RootCause := E_Heating_RootCause.RC_SENSOR_ERROR;
    VO_Confidence := 0.7;
    RETURN;
END_IF;

VO_RootCause := E_Heating_RootCause.RC_NONE;
VO_Confidence := 0.0;

END_FUNCTION_BLOCK
