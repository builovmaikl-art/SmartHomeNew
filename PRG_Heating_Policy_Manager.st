PROGRAM PRG_Heating_Policy_Manager

VAR
    fbPolicyManager : FB_Heating_Policy_Manager;
    fbSchedule : FB_Heating_Schedule_Preheat;
    fbTime : FB_Time_Service;
    L_i : INT;
    L_Room_Avg : REAL;
    L_Floor_Avg : REAL;
END_VAR

// --- TIME SERVICE ---
fbTime();

// --- INPUT AGGREGATION ---
L_Room_Avg := 0.0;
L_Floor_Avg := 0.0;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_ZONES DO
    L_Room_Avg := L_Room_Avg + GVL_STATE.G_Room_Temps[L_i];
    L_Floor_Avg := L_Floor_Avg + GVL_STATE.G_Floor_Temps[L_i];
END_FOR;

L_Room_Avg := L_Room_Avg / REAL(GVL_CONSTANTS.C_MAX_ZONES);
L_Floor_Avg := L_Floor_Avg / REAL(GVL_CONSTANTS.C_MAX_ZONES);

// --- POLICY ---
fbPolicyManager(
    VI_System_Time_MS := GVL_TIME_SERVICE.G_Now_MS,
    VI_System_Mode := GVL_STATE.G_System_Mode,
    VI_RootCause := GVL_STATE.G_Heating_RootCause,
    VI_RootConfidence := GVL_STATE.G_Heating_RootConfidence,
    VI_Min_Hold_MS := GVL_CONFIG.G_Policy_Min_Hold_MS,
    VI_Emergency_Stop := GVL_STATE.G_Safety_Emergency_Stop,
    VI_Gas_Safety := GVL_STATE.G_Safety_Gas_Latched,
    VI_Room_Temp_Avg := L_Room_Avg,
    VI_Floor_Temp_Avg := L_Floor_Avg,
    VI_Supply_Temp := GVL_STATE.G_Manifold_T_Supply[1],
    VI_Return_Temp := GVL_STATE.G_Manifold_T_Return[1],
    VI_Target_Temp := GVL_STATE.G_Target_Temperature,
    VI_Room_Temps := GVL_STATE.G_Room_Temps,
    VI_Floor_Temps := GVL_STATE.G_Floor_Temps
);

// --- SCHEDULE ---
fbSchedule(
    VI_System_Time_MS := GVL_TIME_SERVICE.G_Now_MS,
    VI_Time_Of_Day_MS := GVL_TIME_SERVICE.G_Time_Of_Day_MS,
    VI_Day_Of_Week := GVL_TIME_SERVICE.G_Day_Of_Week,
    VI_Enable := TRUE
);

// --- OUTPUT ---
GVL_HEATING_POLICY.G_Policy_Mode := fbPolicyManager.VO_Policy_Mode;
GVL_HEATING_POLICY.G_Policy_Block_Heating_Request := fbPolicyManager.VO_Block_Heating;
GVL_HEATING_POLICY.G_Policy_Target_Adjustment := fbPolicyManager.VO_Target_Adjustment;
GVL_HEATING_POLICY.G_Policy_Priority_Multiplier := fbPolicyManager.VO_Priority_Multiplier;
GVL_HEATING_POLICY.G_Policy_Self_Tune_Active := fbPolicyManager.VO_Self_Tune_Active;
GVL_HEATING_POLICY.G_Policy_Self_Tune_Level := fbPolicyManager.VO_Self_Tune_Level;
GVL_HEATING_POLICY.G_Policy_Feedback_Stable := fbPolicyManager.VO_Feedback_Stable;
GVL_HEATING_POLICY.G_Policy_Feedback_Improving := fbPolicyManager.VO_Feedback_Improving;
GVL_HEATING_POLICY.G_Policy_Feedback_Quality := fbPolicyManager.VO_Feedback_Quality;
