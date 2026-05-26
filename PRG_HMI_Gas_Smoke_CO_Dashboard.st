PROGRAM PRG_HMI_Gas_Smoke_CO_Dashboard
VAR
    L_i : INT;
    L_Methane_Max : REAL;
    L_CO_Max : REAL;
    L_Smoke_Count : UINT;
    L_Targeted : BOOL;
END_VAR

L_Methane_Max := 0.0;
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_METHANE_SENSORS DO
    GVL_HMI_GAS_SMOKE_CO.G_Methane_Effective[L_i] := GVL_Safety_Selector.G_Methane_Effective_Array[L_i];
    IF GVL_Safety_Selector.G_Methane_Effective_Array[L_i] > L_Methane_Max THEN
        L_Methane_Max := GVL_Safety_Selector.G_Methane_Effective_Array[L_i];
    END_IF;
END_FOR;
GVL_HMI_GAS_SMOKE_CO.G_Methane_Max_LEL := GVL_METHANE_REDUNDANCY.G_Max_LEL;
GVL_HMI_GAS_SMOKE_CO.G_Methane_Min_LEL := GVL_METHANE_REDUNDANCY.G_Min_LEL;
GVL_HMI_GAS_SMOKE_CO.G_Methane_Diff_LEL := GVL_METHANE_REDUNDANCY.G_Diff_LEL;
GVL_HMI_GAS_SMOKE_CO.G_Methane_Max_Sensor_Index := GVL_METHANE_REDUNDANCY.G_Max_Sensor_Index;
GVL_HMI_GAS_SMOKE_CO.G_Methane_Disagreement_Active := GVL_METHANE_REDUNDANCY.G_Disagreement_Active;
GVL_HMI_GAS_SMOKE_CO.G_Methane_Disagreement_Limit_LEL := GVL_METHANE_REDUNDANCY.G_Disagreement_Limit_LEL;
GVL_HMI_GAS_SMOKE_CO.G_Methane_Redundancy_Available := GVL_METHANE_REDUNDANCY.G_Redundancy_Available;
GVL_HMI_GAS_SMOKE_CO.G_Methane_Conservative_Max_Selected := GVL_METHANE_REDUNDANCY.G_Conservative_Max_Selected;
GVL_HMI_GAS_SMOKE_CO.G_Methane_Redundancy_Status_Text := GVL_METHANE_REDUNDANCY.G_Status_Text;
GVL_HMI_GAS_SMOKE_CO.G_Methane_Redundancy_Last_Update_MS := GVL_METHANE_REDUNDANCY.G_Last_Update_MS;

L_CO_Max := 0.0;
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_CO_SENSORS DO
    GVL_HMI_GAS_SMOKE_CO.G_CO_Effective[L_i] := GVL_Safety_Selector.G_CO_Effective_Array[L_i];
    IF GVL_Safety_Selector.G_CO_Effective_Array[L_i] > L_CO_Max THEN
        L_CO_Max := GVL_Safety_Selector.G_CO_Effective_Array[L_i];
    END_IF;
END_FOR;
GVL_HMI_GAS_SMOKE_CO.G_CO_Max_PPM := L_CO_Max;
GVL_HMI_GAS_SMOKE_CO.G_CO_Max_Sensor_Index := GVL_CO_EXPOSURE.G_CO_Max_Sensor_Index;
GVL_HMI_GAS_SMOKE_CO.G_CO_Level_30ppm_Active := GVL_CO_EXPOSURE.G_Level_30ppm_Active;
GVL_HMI_GAS_SMOKE_CO.G_CO_Level_70ppm_Active := GVL_CO_EXPOSURE.G_Level_70ppm_Active;
GVL_HMI_GAS_SMOKE_CO.G_CO_Level_400ppm_Active := GVL_CO_EXPOSURE.G_Level_400ppm_Active;
GVL_HMI_GAS_SMOKE_CO.G_CO_Timer_30ppm_ET := GVL_CO_EXPOSURE.G_Timer_30ppm_ET;
GVL_HMI_GAS_SMOKE_CO.G_CO_Timer_70ppm_ET := GVL_CO_EXPOSURE.G_Timer_70ppm_ET;
GVL_HMI_GAS_SMOKE_CO.G_CO_Timer_400ppm_ET := GVL_CO_EXPOSURE.G_Timer_400ppm_ET;
GVL_HMI_GAS_SMOKE_CO.G_CO_Timer_30ppm_Q := GVL_CO_EXPOSURE.G_Timer_30ppm_Q;
GVL_HMI_GAS_SMOKE_CO.G_CO_Timer_70ppm_Q := GVL_CO_EXPOSURE.G_Timer_70ppm_Q;
GVL_HMI_GAS_SMOKE_CO.G_CO_Timer_400ppm_Q := GVL_CO_EXPOSURE.G_Timer_400ppm_Q;
GVL_HMI_GAS_SMOKE_CO.G_CO_Exposure_Status_Text := GVL_CO_EXPOSURE.G_Status_Text;
GVL_HMI_GAS_SMOKE_CO.G_CO_Exposure_Last_Update_MS := GVL_CO_EXPOSURE.G_Last_Update_MS;

L_Smoke_Count := 0;
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SMOKE_SENSORS DO
    GVL_HMI_GAS_SMOKE_CO.G_Smoke_Effective[L_i] := GVL_Safety_Selector.G_Smoke_Effective_Array[L_i];
    IF GVL_Safety_Selector.G_Smoke_Effective_Array[L_i] THEN
        L_Smoke_Count := L_Smoke_Count + 1;
    END_IF;
END_FOR;
GVL_HMI_GAS_SMOKE_CO.G_Smoke_Active_Count := L_Smoke_Count;

GVL_HMI_GAS_SMOKE_CO.G_Smoke_Any_Input_Active := GVL_SMOKE_VERIFICATION.G_Any_Smoke_Input_Active;
FOR L_i := 1 TO 3 DO
    GVL_HMI_GAS_SMOKE_CO.G_Smoke_Group_Active[L_i] := GVL_SMOKE_VERIFICATION.G_Group_Active[L_i];
    GVL_HMI_GAS_SMOKE_CO.G_Smoke_Group_Pair_Confirmed[L_i] := GVL_SMOKE_VERIFICATION.G_Group_Pair_Confirmed[L_i];
    GVL_HMI_GAS_SMOKE_CO.G_Smoke_Group_Timer_Confirmed[L_i] := GVL_SMOKE_VERIFICATION.G_Group_Timer_Confirmed[L_i];
END_FOR;
GVL_HMI_GAS_SMOKE_CO.G_Smoke_Verified_By_Pair := GVL_SMOKE_VERIFICATION.G_Verified_By_Pair;
GVL_HMI_GAS_SMOKE_CO.G_Smoke_Verified_By_Timer := GVL_SMOKE_VERIFICATION.G_Verified_By_Timer;
GVL_HMI_GAS_SMOKE_CO.G_Smoke_Verified_Group := GVL_SMOKE_VERIFICATION.G_Verified_Group;
GVL_HMI_GAS_SMOKE_CO.G_Smoke_Verification_Text := GVL_SMOKE_VERIFICATION.G_Status_Text;
GVL_HMI_GAS_SMOKE_CO.G_Smoke_Verification_Last_Update_MS := GVL_SMOKE_VERIFICATION.G_Last_Update_MS;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_EXHAUST_FANS DO
    GVL_HMI_GAS_SMOKE_CO.G_Smoke_Target_Exhaust_Fans[L_i] := FALSE;
END_FOR;

L_Targeted := FALSE;
CASE GVL_SMOKE_VERIFICATION.G_Verified_Group OF
    2:
        IF GVL_CONSTANTS.C_MAX_EXHAUST_FANS >= 1 THEN
            GVL_HMI_GAS_SMOKE_CO.G_Smoke_Target_Exhaust_Fans[1] := TRUE;
            L_Targeted := TRUE;
        END_IF;
        IF GVL_CONSTANTS.C_MAX_EXHAUST_FANS >= 5 THEN
            GVL_HMI_GAS_SMOKE_CO.G_Smoke_Target_Exhaust_Fans[5] := TRUE;
            L_Targeted := TRUE;
        END_IF;
    3:
        IF GVL_CONSTANTS.C_MAX_EXHAUST_FANS >= 2 THEN
            GVL_HMI_GAS_SMOKE_CO.G_Smoke_Target_Exhaust_Fans[2] := TRUE;
            L_Targeted := TRUE;
        END_IF;
        IF GVL_CONSTANTS.C_MAX_EXHAUST_FANS >= 3 THEN
            GVL_HMI_GAS_SMOKE_CO.G_Smoke_Target_Exhaust_Fans[3] := TRUE;
            L_Targeted := TRUE;
        END_IF;
ELSE
        L_Targeted := FALSE;
END_CASE;

GVL_HMI_GAS_SMOKE_CO.G_Smoke_Exhaust_Target_Group := GVL_SMOKE_VERIFICATION.G_Verified_Group;
GVL_HMI_GAS_SMOKE_CO.G_Smoke_Exhaust_Targeted :=
    GVL_COMMAND_SHADOW.G_Vent_Smoke_Exhaust AND L_Targeted;
GVL_HMI_GAS_SMOKE_CO.G_Smoke_Exhaust_Fallback_All :=
    GVL_COMMAND_SHADOW.G_Vent_Smoke_Exhaust AND NOT L_Targeted;

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

GVL_HMI_GAS_SMOKE_CO.G_Command_Gas_Valve_Close := GVL_COMMAND_SHADOW.G_Gas_Valve_Close;
GVL_HMI_GAS_SMOKE_CO.G_Command_Boiler_Stop := GVL_COMMAND_SHADOW.G_Boiler_Stop;
GVL_HMI_GAS_SMOKE_CO.G_Output_Gas_Valve_Close := GVL_IO.DO_Gas_Valve_Close;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BOILERS DO
    GVL_HMI_GAS_SMOKE_CO.G_OpenTherm_Command_Enable[L_i] := GVL_OPENTHERM_ADAPTER.G_Command[L_i].Enable;
    GVL_HMI_GAS_SMOKE_CO.G_OpenTherm_Command_Setpoint_x10[L_i] := GVL_OPENTHERM_ADAPTER.G_Command[L_i].Setpoint_x10;
    GVL_HMI_GAS_SMOKE_CO.G_OpenTherm_Command_Sequence[L_i] := GVL_OPENTHERM_ADAPTER.G_Command[L_i].Sequence;
    GVL_HMI_GAS_SMOKE_CO.G_OpenTherm_Wire_Enable[L_i] := GVL_OPENTHERM_ADAPTER.G_Wire_Image[L_i].Cmd_Enable;
    GVL_HMI_GAS_SMOKE_CO.G_OpenTherm_Wire_Setpoint_x10[L_i] := GVL_OPENTHERM_ADAPTER.G_Wire_Image[L_i].Cmd_Setpoint_x10;
END_FOR;

GVL_HMI_GAS_SMOKE_CO.G_Vent_Output_Enable := GVL_VENT_OUTPUT.DO_Vent_Enable;
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SUPPLY_FANS DO
    GVL_HMI_GAS_SMOKE_CO.G_Vent_Output_Supply_Fans[L_i] := GVL_VENT_OUTPUT.AO_Supply_Fans[L_i];
END_FOR;
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_EXHAUST_FANS DO
    GVL_HMI_GAS_SMOKE_CO.G_Vent_Output_Exhaust_Fans[L_i] := GVL_VENT_OUTPUT.AO_Exhaust_Fans[L_i];
END_FOR;

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
