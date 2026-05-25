PROGRAM PRG_Config_Staged_Change_Monitor
// ==============================================================================
// CONFIG STAGED CHANGE MONITOR
// ==============================================================================
// Tracks generic staged config fields controlled by GVL_CONFIG_CONTROL. When any
// staged value changes, the staged config version is incremented so HMI validation
// cannot be reused for a different draft.
// ==============================================================================
VAR
    L_Initialized : BOOL;
    L_Changed : BOOL;

    L_Last_STG_Reputation_Learning_Rate : REAL;
    L_Last_STG_Reputation_Recovery_Decay : REAL;
    L_Last_STG_Min_Sensor_Confidence : REAL;
    L_Last_STG_Bad_Spike_Confidence : REAL;
    L_Last_STG_Default_Confidence : REAL;

    L_Last_STG_Night_Start_Hour : INT;
    L_Last_STG_Night_End_Hour : INT;
    L_Last_STG_VentBoost_Humidity_Threshold : REAL;

    L_Last_STG_Stabilization_Delay_MS : UDINT;

    L_Last_STG_PLC_Inactive_Close_Gas : BOOL;
    L_Last_STG_PLC_Inactive_Stop_Boiler : BOOL;
    L_Last_STG_PLC_Inactive_Block_Heating : BOOL;
    L_Last_STG_PLC_Inactive_Stop_Vent : BOOL;
    L_Last_STG_PLC_Inactive_Block_Water : BOOL;
END_VAR

L_Changed := FALSE;

IF NOT L_Initialized THEN
    L_Initialized := TRUE;
ELSE
    IF L_Last_STG_Reputation_Learning_Rate <> GVL_CONFIG_CONTROL.STG_Reputation_Learning_Rate THEN L_Changed := TRUE; END_IF;
    IF L_Last_STG_Reputation_Recovery_Decay <> GVL_CONFIG_CONTROL.STG_Reputation_Recovery_Decay THEN L_Changed := TRUE; END_IF;
    IF L_Last_STG_Min_Sensor_Confidence <> GVL_CONFIG_CONTROL.STG_Min_Sensor_Confidence THEN L_Changed := TRUE; END_IF;
    IF L_Last_STG_Bad_Spike_Confidence <> GVL_CONFIG_CONTROL.STG_Bad_Spike_Confidence THEN L_Changed := TRUE; END_IF;
    IF L_Last_STG_Default_Confidence <> GVL_CONFIG_CONTROL.STG_Default_Confidence THEN L_Changed := TRUE; END_IF;

    IF L_Last_STG_Night_Start_Hour <> GVL_CONFIG_CONTROL.STG_Night_Start_Hour THEN L_Changed := TRUE; END_IF;
    IF L_Last_STG_Night_End_Hour <> GVL_CONFIG_CONTROL.STG_Night_End_Hour THEN L_Changed := TRUE; END_IF;
    IF L_Last_STG_VentBoost_Humidity_Threshold <> GVL_CONFIG_CONTROL.STG_VentBoost_Humidity_Threshold THEN L_Changed := TRUE; END_IF;

    IF L_Last_STG_Stabilization_Delay_MS <> GVL_CONFIG_CONTROL.STG_Stabilization_Delay_MS THEN L_Changed := TRUE; END_IF;

    IF L_Last_STG_PLC_Inactive_Close_Gas <> GVL_CONFIG_CONTROL.STG_PLC_Inactive_Close_Gas THEN L_Changed := TRUE; END_IF;
    IF L_Last_STG_PLC_Inactive_Stop_Boiler <> GVL_CONFIG_CONTROL.STG_PLC_Inactive_Stop_Boiler THEN L_Changed := TRUE; END_IF;
    IF L_Last_STG_PLC_Inactive_Block_Heating <> GVL_CONFIG_CONTROL.STG_PLC_Inactive_Block_Heating THEN L_Changed := TRUE; END_IF;
    IF L_Last_STG_PLC_Inactive_Stop_Vent <> GVL_CONFIG_CONTROL.STG_PLC_Inactive_Stop_Vent THEN L_Changed := TRUE; END_IF;
    IF L_Last_STG_PLC_Inactive_Block_Water <> GVL_CONFIG_CONTROL.STG_PLC_Inactive_Block_Water THEN L_Changed := TRUE; END_IF;
END_IF;

IF L_Changed THEN
    GVL_CONFIG_CONTROL.G_Staged_Config_Version := GVL_CONFIG_CONTROL.G_Staged_Config_Version + 1;
    GVL_CONFIG_CONTROL.G_Staged_Last_Changed_MS := GVL_TIME_SERVICE.G_Now_MS;
END_IF;

L_Last_STG_Reputation_Learning_Rate := GVL_CONFIG_CONTROL.STG_Reputation_Learning_Rate;
L_Last_STG_Reputation_Recovery_Decay := GVL_CONFIG_CONTROL.STG_Reputation_Recovery_Decay;
L_Last_STG_Min_Sensor_Confidence := GVL_CONFIG_CONTROL.STG_Min_Sensor_Confidence;
L_Last_STG_Bad_Spike_Confidence := GVL_CONFIG_CONTROL.STG_Bad_Spike_Confidence;
L_Last_STG_Default_Confidence := GVL_CONFIG_CONTROL.STG_Default_Confidence;

L_Last_STG_Night_Start_Hour := GVL_CONFIG_CONTROL.STG_Night_Start_Hour;
L_Last_STG_Night_End_Hour := GVL_CONFIG_CONTROL.STG_Night_End_Hour;
L_Last_STG_VentBoost_Humidity_Threshold := GVL_CONFIG_CONTROL.STG_VentBoost_Humidity_Threshold;

L_Last_STG_Stabilization_Delay_MS := GVL_CONFIG_CONTROL.STG_Stabilization_Delay_MS;

L_Last_STG_PLC_Inactive_Close_Gas := GVL_CONFIG_CONTROL.STG_PLC_Inactive_Close_Gas;
L_Last_STG_PLC_Inactive_Stop_Boiler := GVL_CONFIG_CONTROL.STG_PLC_Inactive_Stop_Boiler;
L_Last_STG_PLC_Inactive_Block_Heating := GVL_CONFIG_CONTROL.STG_PLC_Inactive_Block_Heating;
L_Last_STG_PLC_Inactive_Stop_Vent := GVL_CONFIG_CONTROL.STG_PLC_Inactive_Stop_Vent;
L_Last_STG_PLC_Inactive_Block_Water := GVL_CONFIG_CONTROL.STG_PLC_Inactive_Block_Water;

// >>> BULK_SYNC_ANCHOR: PRG_Config_Staged_Change_Monitor <<<
END_PROGRAM
