PROGRAM PRG_Presence_Manager
VAR
    fbPresence : FB_Presence_Manager;
END_VAR

fbPresence(
    VI_Motion_Sensors := GVL_STATE.G_Motion_Sensors,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

GVL_PRESENCE.G_Any_Motion := fbPresence.VO_Any_Motion;
GVL_PRESENCE.G_Occupied := fbPresence.VO_Occupied;
GVL_PRESENCE.G_Auto_Away_Request := fbPresence.VO_Auto_Away;
GVL_PRESENCE.G_Last_Motion_TS := fbPresence.VO_Last_Motion_TS;
