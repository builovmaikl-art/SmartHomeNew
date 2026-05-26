PROGRAM PRG_HMI_Gas_Smoke_CO_Dashboard
VAR
    L_i : INT;
    L_Methane_Max : REAL;
    L_CO_Max : REAL;
    L_Smoke_Count : UINT;
END_VAR

L_Methane_Max := 0.0;
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_METHANE_SENSORS DO
    GVL_HMI_GAS_SMOKE_CO.G_Methane_Effective[L_i] := GVL_Safety_Selector.G_Methane_Effective_Array[L_i];
    IF GVL_Safety_Selector.G_Methane_Effective_Array[L_i] > L_Methane_Max THEN
        L_Methane_Max := GVL_Safety_Selector.G_Methane_Effective_Array[L_i];
    END_IF;
END_FOR;
GVL_HMI_GAS_SMOKE_CO.G_Methane_Max_LEL := L_Methane_Max;

L_CO_Max := 0.0;
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_CO_SENSORS DO
    GVL_HMI_GAS_SMOKE_CO.G_CO_Effective[L_i] := GVL_Safety_Selector.G_CO_Effective_Array[L_i];
    IF GVL_Safety_Selector.G_CO_Effective_Array[L_i] > L_CO_Max THEN
        L_CO_Max := GVL_Safety_Selector.G_CO_Effective_Array[L_i];
    END_IF;
END_FOR;
GVL_HMI_GAS_SMOKE_CO.G_CO_Max_PPM := L_CO_Max;

L_Smoke_Count := 0;
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SMOKE_SENSORS DO
    GVL_HMI_GAS_SMOKE_CO.G_Smoke_Effective[L_i] := GVL_Safety_Selector.G_Smoke_Effective_Array[L_i];
    IF GVL_Safety_Selector.G_Smoke_Effective_Array[L_i] THEN
        L_Smoke_Count := L_Smoke_Count + 1;
    END_IF;
END_FOR;
GVL_HMI_GAS_SMOKE_CO.G_Smoke_Active_Count := L_Smoke_Count;

GVL_HMI_GAS_SMOKE_CO.G_Methane_Warning_Level := GVL_HEALTH_BRIDGE.G_Methane_Warning_Level;
GVL_HMI_GAS_SMOKE_CO.G_Methane_Alarm_Level := GVL_HEALTH_BRIDGE.G_Methane_Alarm_Level;
GVL_HMI_GAS_SMOKE_CO.G_Methane_Critical_Level := GVL_HEALTH_BRIDGE.G_Methane_Critical_Level;
GVL_HMI_GAS_SMOKE_CO.G_CO_Warning_Level := GVL_HEALTH_BRIDGE.G_CO_Warning_Level;
GVL_HMI_GAS_SMOKE_CO.G_CO_Alarm_Level := GVL_HEALTH_BRIDGE.G_CO_Alarm_Level;
GVL_HMI_GAS_SMOKE_CO.G_Smoke_Detected := GVL_HEALTH_BRIDGE.G_Smoke_Detected;
GVL_HMI_GAS_SMOKE_CO.G_Gas_Detected := GVL_HEALTH_BRIDGE.G_Gas_Detected;
GVL_HMI_GAS_SMOKE_CO.G_Status_Text := GVL_STATUS.G_Gas_Status_Msg;

GVL_HMI_GAS_SMOKE_CO.G_Safety_Fire_Alarm_Active := GVL_INTENT_SAFETY.I_Fire_Alarm_Active;
GVL_HMI_GAS_SMOKE_CO.G_Safety_Gas_Alarm_Active := GVL_INTENT_SAFETY.I_Gas_Alarm_Active;
GVL_HMI_GAS_SMOKE_CO.G_Safety_CO_Warning_Active := GVL_INTENT_SAFETY.I_CO_Warning_Active;
GVL_HMI_GAS_SMOKE_CO.G_Gas_Close_Required := GVL_INTENT_SAFETY.I_Gas_Close_Required;
GVL_HMI_GAS_SMOKE_CO.G_Boiler_Stop_Required := GVL_INTENT_SAFETY.I_Boiler_Stop_Required;
GVL_HMI_GAS_SMOKE_CO.G_System_Safe_Stop_Required := GVL_INTENT_SAFETY.I_System_Safe_Stop_Required;
GVL_HMI_GAS_SMOKE_CO.G_Evacuation_Mode_Active := GVL_INTENT_SAFETY.I_Evacuation_Mode_Active;
GVL_HMI_GAS_SMOKE_CO.G_Vent_Stop_Required := GVL_INTENT_SAFETY.I_Vent_Stop_Required;
GVL_HMI_GAS_SMOKE_CO.G_Vent_Force_PV3_Boost := GVL_INTENT_SAFETY.I_Vent_Force_PV3_Boost;
GVL_HMI_GAS_SMOKE_CO.G_Vent_Force_Supply_100 := GVL_INTENT_SAFETY.I_Vent_Force_Supply_100;
GVL_HMI_GAS_SMOKE_CO.G_Vent_Force_Supply_80 := GVL_INTENT_SAFETY.I_Vent_Force_Supply_80;
GVL_HMI_GAS_SMOKE_CO.G_Vent_Force_Exhaust_100 := GVL_INTENT_SAFETY.I_Vent_Force_Exhaust_100;

IF GVL_HEALTH_BRIDGE.G_Methane_Critical_Level OR GVL_INTENT_SAFETY.I_System_Safe_Stop_Required THEN
    GVL_HMI_GAS_SMOKE_CO.G_Status_Level := 3;
ELSIF GVL_HEALTH_BRIDGE.G_Methane_Alarm_Level OR GVL_HEALTH_BRIDGE.G_CO_Alarm_Level OR GVL_HEALTH_BRIDGE.G_Smoke_Detected THEN
    GVL_HMI_GAS_SMOKE_CO.G_Status_Level := 2;
ELSIF GVL_HEALTH_BRIDGE.G_Methane_Warning_Level OR GVL_HEALTH_BRIDGE.G_CO_Warning_Level THEN
    GVL_HMI_GAS_SMOKE_CO.G_Status_Level := 1;
ELSE
    GVL_HMI_GAS_SMOKE_CO.G_Status_Level := 0;
END_IF;

// >>> BULK_SYNC_ANCHOR: PRG_HMI_Gas_Smoke_CO_Dashboard <<<
END_PROGRAM
