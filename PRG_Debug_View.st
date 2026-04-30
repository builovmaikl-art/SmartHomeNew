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

// current profile
GVL_DEBUG_VIEW.D_Adapt_Profile := GVL_BEHAVIOR_ADAPT.G_Adapt_Profile;

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

GVL_DEBUG_VIEW.D_Last_Trace_Text :=
    GVL_TRACE.G_Trace_Buffer[L_Index].Text;

GVL_DEBUG_VIEW.D_Last_Trace_Time_MS :=
    GVL_TRACE.G_Trace_Buffer[L_Index].Timestamp_MS;

GVL_DEBUG_VIEW.D_Last_Trace_Reason :=
    GVL_TRACE.G_Trace_Buffer[L_Index].Reason_Code;

END_PROGRAM