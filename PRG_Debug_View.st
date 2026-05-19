PROGRAM PRG_Debug_View
VAR
    L_i : INT;
    L_MaxWeight : REAL;
    L_MinWeight : REAL;
    L_Weight : REAL;
    L_Index : INT;
END_VAR

GVL_DEBUG_VIEW.D_Current_Time_MS := GVL_TIME_SERVICE.G_Now_MS;

GVL_DEBUG_VIEW.D_Safety_Mode := GVL_SAFETY_SHUTDOWN.G_Safety_Mode;
GVL_DEBUG_VIEW.D_Safety_Active := (GVL_SAFETY_SHUTDOWN.G_Safety_Mode <> NORMAL);
GVL_DEBUG_VIEW.D_Recovery_Phase := GVL_SAFETY_RECOVERY.G_Recovery_Phase;
GVL_DEBUG_VIEW.D_Recovery_Active := GVL_SAFETY_RECOVERY.G_Recovery_Active;

GVL_DEBUG_VIEW.D_Current_Scenario := GVL_INTENT_BEHAVIOR.I_Selected_Scenario_Text;
GVL_DEBUG_VIEW.D_Behavior_Reason := GVL_INTENT_BEHAVIOR.I_Reason_Text;

GVL_DEBUG_VIEW.D_Score_Night := GVL_INTENT_BEHAVIOR.I_Score_Night;
GVL_DEBUG_VIEW.D_Score_Preheat := GVL_INTENT_BEHAVIOR.I_Score_Preheat;
GVL_DEBUG_VIEW.D_Score_VentBoost := GVL_INTENT_BEHAVIOR.I_Score_Vent_Boost;
GVL_DEBUG_VIEW.D_Score_AccessSecure := GVL_INTENT_BEHAVIOR.I_Score_Access_Secure;

GVL_DEBUG_VIEW.D_Intent_Night := GVL_INTENT_BEHAVIOR.I_Request_Night_Mode;
GVL_DEBUG_VIEW.D_Intent_Comfort := GVL_INTENT_BEHAVIOR.I_Request_Comfort_Mode;
GVL_DEBUG_VIEW.D_Intent_VentBoost := GVL_INTENT_BEHAVIOR.I_Request_Ventilation_Boost;
GVL_DEBUG_VIEW.D_Intent_AccessSecure := GVL_INTENT_BEHAVIOR.I_Request_Access_Secure_Mode;

GVL_DEBUG_VIEW.D_Heating_Block := GVL_COMMAND_SHADOW.G_Heating_Block;
GVL_DEBUG_VIEW.D_Vent_Stop := GVL_COMMAND_SHADOW.G_Vent_Stop;
GVL_DEBUG_VIEW.D_Water_Block := GVL_COMMAND_SHADOW.G_Water_Block;
GVL_DEBUG_VIEW.D_Access_Open_Active := GVL_COMMAND_SHADOW.G_Gate_Open OR GVL_COMMAND_SHADOW.G_Wicket_Open;

GVL_DEBUG_VIEW.D_Global_Reason := GVL_EXPLAINABILITY.G_Last_Global_Reason_Text;
GVL_DEBUG_VIEW.D_Behavior_Why_Active := GVL_EXPLAINABILITY.G_Behavior_Why_Active;
GVL_DEBUG_VIEW.D_Heating_Why_Blocked := GVL_EXPLAINABILITY.G_Heating_Why_Blocked;
GVL_DEBUG_VIEW.D_Vent_Why_Stopped := GVL_EXPLAINABILITY.G_Vent_Why_Stopped;
GVL_DEBUG_VIEW.D_Water_Why_Closed := GVL_EXPLAINABILITY.G_Water_Why_Closed;
GVL_DEBUG_VIEW.D_Access_Why_Opened := GVL_EXPLAINABILITY.G_Access_Why_Opened;

// MAIN PHASE FEEDBACK SUMMARY -> DEBUG VIEW
GVL_DEBUG_VIEW.D_Main_Phase_Current := GVL_MAIN_PHASE_FEEDBACK.G_Current_Phase;
GVL_DEBUG_VIEW.D_Main_Phase_Critical_Executed := GVL_MAIN_PHASE_FEEDBACK.G_Critical_Path_Executed;
GVL_DEBUG_VIEW.D_Main_Phase_Critical_Valid := GVL_MAIN_PHASE_FEEDBACK.G_Critical_Path_Valid;
GVL_DEBUG_VIEW.D_Main_Phase_Observability_Executed := GVL_MAIN_PHASE_FEEDBACK.G_Observability_Path_Executed;
GVL_DEBUG_VIEW.D_Main_Phase_Observability_Valid := GVL_MAIN_PHASE_FEEDBACK.G_Observability_Path_Valid;
GVL_DEBUG_VIEW.D_Main_Phase_Any_Invalid := GVL_MAIN_PHASE_FEEDBACK.G_Any_Phase_Invalid;
GVL_DEBUG_VIEW.D_Main_Phase_Any_Skipped_By_Design := GVL_MAIN_PHASE_FEEDBACK.G_Any_Phase_Skipped_By_Design;
GVL_DEBUG_VIEW.D_Main_Phase_Status_Code := GVL_MAIN_PHASE_FEEDBACK.G_Status_Code;
GVL_DEBUG_VIEW.D_Main_Phase_Status_Text := GVL_MAIN_PHASE_FEEDBACK.G_Status_Text;

// DOMAIN EXECUTION POLICY SUMMARY -> DEBUG VIEW
GVL_DEBUG_VIEW.D_Domain_Policy_Any_Critical := GVL_DOMAIN_EXECUTION_POLICY.Any_Critical_Run;
GVL_DEBUG_VIEW.D_Domain_Policy_Any_Periodic := GVL_DOMAIN_EXECUTION_POLICY.Any_Periodic_Run;
GVL_DEBUG_VIEW.D_Domain_Policy_Any_Periodic_Due := GVL_DOMAIN_EXECUTION_POLICY.Any_Periodic_Due;
GVL_DEBUG_VIEW.D_Domain_Policy_Any_Idle := GVL_DOMAIN_EXECUTION_POLICY.Any_Idle_By_Design;
GVL_DEBUG_VIEW.D_Domain_Policy_Status_Code := GVL_DOMAIN_EXECUTION_POLICY.Status_Code;
GVL_DEBUG_VIEW.D_Domain_Policy_Status_Text := GVL_DOMAIN_EXECUTION_POLICY.Status_Text;

GVL_DEBUG_VIEW.D_Access_Mode := GVL_DOMAIN_EXECUTION_POLICY.Access_Mode;
GVL_DEBUG_VIEW.D_Access_Critical_Run := GVL_DOMAIN_EXECUTION_POLICY.Access_Critical_Run;
GVL_DEBUG_VIEW.D_Access_Periodic_Run := GVL_DOMAIN_EXECUTION_POLICY.Access_Periodic_Run;
GVL_DEBUG_VIEW.D_Access_Periodic_Due := GVL_DOMAIN_EXECUTION_POLICY.Access_Periodic_Due;
GVL_DEBUG_VIEW.D_Access_Idle_By_Design := GVL_DOMAIN_EXECUTION_POLICY.Access_Idle_By_Design;

GVL_DEBUG_VIEW.D_Lighting_Mode := GVL_DOMAIN_EXECUTION_POLICY.Lighting_Mode;
GVL_DEBUG_VIEW.D_Lighting_Critical_Run := GVL_DOMAIN_EXECUTION_POLICY.Lighting_Critical_Run;
GVL_DEBUG_VIEW.D_Lighting_Periodic_Run := GVL_DOMAIN_EXECUTION_POLICY.Lighting_Periodic_Run;
GVL_DEBUG_VIEW.D_Lighting_Periodic_Due := GVL_DOMAIN_EXECUTION_POLICY.Lighting_Periodic_Due;
GVL_DEBUG_VIEW.D_Lighting_Idle_By_Design := GVL_DOMAIN_EXECUTION_POLICY.Lighting_Idle_By_Design;

GVL_DEBUG_VIEW.D_Water_Mode := GVL_DOMAIN_EXECUTION_POLICY.Water_Mode;
GVL_DEBUG_VIEW.D_Water_Critical_Run := GVL_DOMAIN_EXECUTION_POLICY.Water_Critical_Run;
GVL_DEBUG_VIEW.D_Water_Periodic_Run := GVL_DOMAIN_EXECUTION_POLICY.Water_Periodic_Run;
GVL_DEBUG_VIEW.D_Water_Periodic_Due := GVL_DOMAIN_EXECUTION_POLICY.Water_Periodic_Due;
GVL_DEBUG_VIEW.D_Water_Idle_By_Design := GVL_DOMAIN_EXECUTION_POLICY.Water_Idle_By_Design;

GVL_DEBUG_VIEW.D_Heating_Mode := GVL_DOMAIN_EXECUTION_POLICY.Heating_Mode;
GVL_DEBUG_VIEW.D_Heating_Critical_Run := GVL_DOMAIN_EXECUTION_POLICY.Heating_Critical_Run;
GVL_DEBUG_VIEW.D_Heating_Periodic_Run := GVL_DOMAIN_EXECUTION_POLICY.Heating_Periodic_Run;
GVL_DEBUG_VIEW.D_Heating_Periodic_Due := GVL_DOMAIN_EXECUTION_POLICY.Heating_Periodic_Due;
GVL_DEBUG_VIEW.D_Heating_Idle_By_Design := GVL_DOMAIN_EXECUTION_POLICY.Heating_Idle_By_Design;

GVL_DEBUG_VIEW.D_Vent_Mode := GVL_DOMAIN_EXECUTION_POLICY.Vent_Mode;
GVL_DEBUG_VIEW.D_Vent_Critical_Run := GVL_DOMAIN_EXECUTION_POLICY.Vent_Critical_Run;
GVL_DEBUG_VIEW.D_Vent_Periodic_Run := GVL_DOMAIN_EXECUTION_POLICY.Vent_Periodic_Run;
GVL_DEBUG_VIEW.D_Vent_Periodic_Due := GVL_DOMAIN_EXECUTION_POLICY.Vent_Periodic_Due;
GVL_DEBUG_VIEW.D_Vent_Idle_By_Design := GVL_DOMAIN_EXECUTION_POLICY.Vent_Idle_By_Design;

GVL_DEBUG_VIEW.D_Simulation_Mode := GVL_DOMAIN_EXECUTION_POLICY.Simulation_Mode;
GVL_DEBUG_VIEW.D_Simulation_Run_Allowed := GVL_DOMAIN_EXECUTION_POLICY.Simulation_Run_Allowed;
GVL_DEBUG_VIEW.D_Simulation_Periodic_Due := GVL_DOMAIN_EXECUTION_POLICY.Simulation_Periodic_Due;
GVL_DEBUG_VIEW.D_Simulation_Idle_By_Design := GVL_DOMAIN_EXECUTION_POLICY.Simulation_Idle_By_Design;

// DOMAIN EXECUTION VALIDATION SUMMARY -> DEBUG VIEW
GVL_DEBUG_VIEW.D_Domain_Validation_Executed := GVL_DOMAIN_EXECUTION_VALIDATION.G_Validation_Executed;
GVL_DEBUG_VIEW.D_Domain_Validation_Valid := GVL_DOMAIN_EXECUTION_VALIDATION.G_Validation_Valid;
GVL_DEBUG_VIEW.D_Domain_Validation_Any_Stale_Output_Risk := GVL_DOMAIN_EXECUTION_VALIDATION.Any_Stale_Output_Risk;
GVL_DEBUG_VIEW.D_Domain_Validation_Any_Policy_Mismatch := GVL_DOMAIN_EXECUTION_VALIDATION.Any_Policy_Mismatch;
GVL_DEBUG_VIEW.D_Access_Stale_Output_Risk := GVL_DOMAIN_EXECUTION_VALIDATION.Access_Stale_Output_Risk;
GVL_DEBUG_VIEW.D_Lighting_Stale_Output_Risk := GVL_DOMAIN_EXECUTION_VALIDATION.Lighting_Stale_Output_Risk;
GVL_DEBUG_VIEW.D_Water_Stale_Output_Risk := GVL_DOMAIN_EXECUTION_VALIDATION.Water_Stale_Output_Risk;
GVL_DEBUG_VIEW.D_Heating_Stale_Output_Risk := GVL_DOMAIN_EXECUTION_VALIDATION.Heating_Stale_Output_Risk;
GVL_DEBUG_VIEW.D_Vent_Stale_Output_Risk := GVL_DOMAIN_EXECUTION_VALIDATION.Vent_Stale_Output_Risk;
GVL_DEBUG_VIEW.D_Domain_Validation_Status_Code := GVL_DOMAIN_EXECUTION_VALIDATION.Status_Code;
GVL_DEBUG_VIEW.D_Domain_Validation_Status_Text := GVL_DOMAIN_EXECUTION_VALIDATION.Status_Text;

// RUNTIME SCENARIO VALIDATION SUMMARY -> DEBUG VIEW
GVL_DEBUG_VIEW.D_Runtime_Scenario_Validation_Executed := GVL_RUNTIME_SCENARIO_VALIDATION.G_Validation_Executed;
GVL_DEBUG_VIEW.D_Runtime_Scenario_Validation_Valid := GVL_RUNTIME_SCENARIO_VALIDATION.G_Validation_Valid;
GVL_DEBUG_VIEW.D_Runtime_Scenario_Any_Context_Invalid := GVL_RUNTIME_SCENARIO_VALIDATION.Any_Context_Invalid;
GVL_DEBUG_VIEW.D_Runtime_Idle_Context_Active := GVL_RUNTIME_SCENARIO_VALIDATION.Idle_Context_Active;
GVL_DEBUG_VIEW.D_Runtime_Security_Context_Active := GVL_RUNTIME_SCENARIO_VALIDATION.Security_Context_Active;
GVL_DEBUG_VIEW.D_Runtime_Away_Context_Active := GVL_RUNTIME_SCENARIO_VALIDATION.Away_Context_Active;
GVL_DEBUG_VIEW.D_Runtime_Presence_Context_Active := GVL_RUNTIME_SCENARIO_VALIDATION.Presence_Context_Active;
GVL_DEBUG_VIEW.D_Runtime_Fire_Context_Active := GVL_RUNTIME_SCENARIO_VALIDATION.Fire_Context_Active;
GVL_DEBUG_VIEW.D_Runtime_Gas_Context_Active := GVL_RUNTIME_SCENARIO_VALIDATION.Gas_Context_Active;
GVL_DEBUG_VIEW.D_Runtime_Leak_Context_Active := GVL_RUNTIME_SCENARIO_VALIDATION.Leak_Context_Active;
GVL_DEBUG_VIEW.D_Runtime_Global_Stop_Context_Active := GVL_RUNTIME_SCENARIO_VALIDATION.Global_Stop_Context_Active;
GVL_DEBUG_VIEW.D_Runtime_Freeze_Context_Active := GVL_RUNTIME_SCENARIO_VALIDATION.Freeze_Context_Active;
GVL_DEBUG_VIEW.D_Runtime_Heating_Context_Valid := GVL_RUNTIME_SCENARIO_VALIDATION.Heating_Context_Valid;
GVL_DEBUG_VIEW.D_Runtime_Vent_Context_Valid := GVL_RUNTIME_SCENARIO_VALIDATION.Vent_Context_Valid;
GVL_DEBUG_VIEW.D_Runtime_Access_Context_Valid := GVL_RUNTIME_SCENARIO_VALIDATION.Access_Context_Valid;
GVL_DEBUG_VIEW.D_Runtime_Global_Stop_Context_Valid := GVL_RUNTIME_SCENARIO_VALIDATION.Global_Stop_Context_Valid;
GVL_DEBUG_VIEW.D_Runtime_Scenario_Status_Code := GVL_RUNTIME_SCENARIO_VALIDATION.Status_Code;
GVL_DEBUG_VIEW.D_Runtime_Scenario_Status_Text := GVL_RUNTIME_SCENARIO_VALIDATION.Status_Text;

// SENSOR QUALITY → HMI
GVL_DEBUG_VIEW.D_Input_Source_Valid := GVL_INPUT.IN_Source_Valid;
GVL_DEBUG_VIEW.D_Input_Degraded := GVL_INPUT.IN_Input_Degraded;
GVL_DEBUG_VIEW.D_Sensor_Fault := GVL_INPUT.IN_Sensor_Fault;
GVL_DEBUG_VIEW.D_Validation_Failed := GVL_INPUT.IN_Validation_Failed;
GVL_DEBUG_VIEW.D_Anomaly_Detected := GVL_INPUT.IN_Anomaly_Detected;
GVL_DEBUG_VIEW.D_Validation_Reason := GVL_INPUT.IN_Validation_Reason;
GVL_DEBUG_VIEW.D_Anomaly_Reason := GVL_INPUT.IN_Anomaly_Reason;
GVL_DEBUG_VIEW.D_Last_Invalid_Zone := GVL_INPUT.IN_Last_Invalid_Zone;
GVL_DEBUG_VIEW.D_Min_Zone_Confidence := GVL_INPUT.IN_Min_Zone_Confidence;
GVL_DEBUG_VIEW.D_Worst_Zone := GVL_INPUT.IN_Worst_Zone;

GVL_DEBUG_VIEW.D_Adapt_Profile := GVL_BEHAVIOR_ADAPT.G_Adapt_Profile;

IF GVL_BEHAVIOR_ADAPT.G_Adapt_Profile = ADAPT_PROFILE_STABLE THEN
    GVL_DEBUG_VIEW.D_Adapt_Profile_Text := 'STABLE';
ELSIF GVL_BEHAVIOR_ADAPT.G_Adapt_Profile = ADAPT_PROFILE_BALANCED THEN
    GVL_DEBUG_VIEW.D_Adapt_Profile_Text := 'BALANCED';
ELSE
    GVL_DEBUG_VIEW.D_Adapt_Profile_Text := 'AGGRESSIVE';
END_IF;

L_MaxWeight := 0.0;
L_MinWeight := 9999.0;
GVL_DEBUG_VIEW.D_Main_VentBoost_Zone := 0;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_ZONES DO
    L_Weight := GVL_BEHAVIOR_ADAPT.G_VentBoost_Zone_Adapt[L_i].Zone_Weight;
    IF L_Weight > L_MaxWeight THEN
        L_MaxWeight := L_Weight;
        GVL_DEBUG_VIEW.D_Main_VentBoost_Zone := L_i;
        GVL_DEBUG_VIEW.D_Main_VentBoost_Zone_Weight := L_Weight;
        GVL_DEBUG_VIEW.D_Main_VentBoost_Zone_Confidence :=
            GVL_BEHAVIOR_ADAPT.G_VentBoost_Zone_Adapt[L_i].Confidence;
    END_IF;
    IF L_Weight < L_MinWeight THEN
        L_MinWeight := L_Weight;
    END_IF;
END_FOR;

GVL_DEBUG_VIEW.D_Max_VentBoost_Zone_Weight := L_MaxWeight;
GVL_DEBUG_VIEW.D_Min_VentBoost_Zone_Weight := L_MinWeight;

L_Index := GVL_TRACE.G_Trace_Write_Index - 1;
IF L_Index < 1 THEN
    L_Index := 200;
END_IF;

GVL_DEBUG_VIEW.D_Last_Trace_Text := GVL_TRACE.G_Trace_Buffer[L_Index].Text;
GVL_DEBUG_VIEW.D_Last_Trace_Time_MS := GVL_TRACE.G_Trace_Buffer[L_Index].Timestamp_MS;
GVL_DEBUG_VIEW.D_Last_Trace_Reason := GVL_TRACE.G_Trace_Buffer[L_Index].Reason_Code;

END_PROGRAM
