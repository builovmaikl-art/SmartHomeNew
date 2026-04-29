PROGRAM PRG_Heating_Policy_Manager

VAR
    fbPolicyManager : FB_Heating_Policy_Manager;
END_VAR

fbPolicyManager(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_System_Mode := GVL_STATE.G_System_Mode,
    VI_RootCause := GVL_STATE.G_Heating_RootCause,
    VI_Emergency_Stop := GVL_STATE.G_Safety_Emergency_Stop,
    VI_Gas_Safety := GVL_STATE.G_Safety_Gas_Latched
);

GVL_HEATING_POLICY.G_Policy_Mode := fbPolicyManager.VO_Policy_Mode;
GVL_HEATING_POLICY.G_Policy_Block_Heating_Request := fbPolicyManager.VO_Block_Heating;
GVL_HEATING_POLICY.G_Policy_Target_Adjustment := fbPolicyManager.VO_Target_Adjustment;
GVL_HEATING_POLICY.G_Policy_Priority_Multiplier := fbPolicyManager.VO_Priority_Multiplier;
