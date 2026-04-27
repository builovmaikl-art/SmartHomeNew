PROGRAM PRG_Heating_Policy_Observer
VAR
    fbPolicy : FB_Heating_Policy_Observer;
END_VAR

fbPolicy(
    VI_Zone_Occupied := GVL_PRESENCE.G_Zone_Occupied,
    VI_Zone_Last_Motion_TS := GVL_PRESENCE.G_Zone_Last_Motion_TS,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Zone_Permanent_Use := GVL_HEATING_POLICY.G_Zone_Permanent_Use,
    VI_Zone_Guest_Preheat := GVL_HEATING_POLICY.G_Zone_Guest_Preheat_Request
);

GVL_HEATING_POLICY.G_Zone_Empty_Duration_MS := fbPolicy.VO_Zone_Empty_Duration_MS;
GVL_HEATING_POLICY.G_Zone_Policy_Class := fbPolicy.VO_Zone_Policy_Class;
GVL_HEATING_POLICY.G_Zone_Target_Adjustment := fbPolicy.VO_Zone_Target_Adjustment;
GVL_HEATING_POLICY.G_Zone_Priority_Bias := fbPolicy.VO_Zone_Priority_Bias;
