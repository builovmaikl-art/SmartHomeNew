PROGRAM PRG_Presence_Manager
VAR
    fbPresence : FB_Presence_Manager;
    L_i : INT;
END_VAR

fbPresence(
    VI_Motion_Sensors := GVL_STATE.G_Motion_Sensors,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

GVL_PRESENCE.G_Any_Motion := fbPresence.VO_Any_Motion;
GVL_PRESENCE.G_Occupied := fbPresence.VO_Occupied;
GVL_PRESENCE.G_Auto_Away_Request := fbPresence.VO_Auto_Away;
GVL_PRESENCE.G_Last_Motion_TS := fbPresence.VO_Last_Motion_TS;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_ZONES DO
    IF GVL_STATE.G_Motion_Sensors[L_i] THEN
        GVL_PRESENCE.G_Zone_Occupied[L_i] := TRUE;
        GVL_PRESENCE.G_Zone_Last_Motion_TS[L_i] := GVL_STATUS.G_System_Time_MS;
    END_IF;

    IF (GVL_STATUS.G_System_Time_MS - GVL_PRESENCE.G_Zone_Last_Motion_TS[L_i]) > 900000 THEN
        GVL_PRESENCE.G_Zone_Occupied[L_i] := FALSE;
    END_IF;
END_FOR;
END_PROGRAM
