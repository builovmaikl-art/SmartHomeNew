PROGRAM PRG_Mode_Manager
VAR
    fbMode : FB_Mode_Manager;
    L_Last_Mode : E_Behavior_Mode := BEHAVIOR_HOME;
END_VAR

fbMode(
    VI_Is_Night := GVL_STATUS.G_Is_Night,
    VI_Away_Request := GVL_MODE.G_Away_Request,
    VI_Maintenance_Request := GVL_MODE.G_Maintenance_Request,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

GVL_MODE.G_Current_Behavior_Mode := fbMode.VO_Mode;
GVL_MODE.G_Mode_Code := fbMode.VO_Mode_Code;

IF L_Last_Mode <> fbMode.VO_Mode THEN
    GVL_MODE.G_Mode_Last_Change_TS := GVL_STATUS.G_System_Time_MS;
    L_Last_Mode := fbMode.VO_Mode;
END_IF;
