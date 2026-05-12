FUNCTION_BLOCK FB_Time_Service
VAR
    L_Real_Now : UDINT;
    L_Elapsed : UDINT;
    L_Scaled_Delta : UDINT;
END_VAR

// read real time
L_Real_Now := GVL_STATUS.G_System_Time_MS;

// wrap-safe delta (real time base)
IF L_Real_Now >= GVL_TIME_SERVICE.G_Last_Now_MS THEN
    L_Elapsed := L_Real_Now - GVL_TIME_SERVICE.G_Last_Now_MS;
    GVL_TIME_SERVICE.G_Wrap_Detected := FALSE;
ELSE
    L_Elapsed := (16#FFFFFFFF - GVL_TIME_SERVICE.G_Last_Now_MS) + L_Real_Now + 1;
    GVL_TIME_SERVICE.G_Wrap_Detected := TRUE;
END_IF;

GVL_TIME_SERVICE.G_Last_Now_MS := L_Real_Now;

// --- SIMULATION MODE ---
IF GVL_TIME_SERVICE.G_Sim_Enabled THEN

    IF NOT GVL_TIME_SERVICE.G_Sim_Frozen THEN
        L_Scaled_Delta := REAL_TO_UDINT(TO_REAL(L_Elapsed) * GVL_TIME_SERVICE.G_Sim_Time_Scale);

        GVL_TIME_SERVICE.G_Sim_Now_MS := GVL_TIME_SERVICE.G_Sim_Now_MS + L_Scaled_Delta;

        GVL_TIME_SERVICE.G_Sim_Time_Of_Day_MS := GVL_TIME_SERVICE.G_Sim_Time_Of_Day_MS + L_Scaled_Delta;

        IF GVL_TIME_SERVICE.G_Sim_Time_Of_Day_MS >= 86400000 THEN
            GVL_TIME_SERVICE.G_Sim_Time_Of_Day_MS := GVL_TIME_SERVICE.G_Sim_Time_Of_Day_MS MOD 86400000;
            GVL_TIME_SERVICE.G_Sim_Day_Of_Week := GVL_TIME_SERVICE.G_Sim_Day_Of_Week + 1;
            IF GVL_TIME_SERVICE.G_Sim_Day_Of_Week > 7 THEN
                GVL_TIME_SERVICE.G_Sim_Day_Of_Week := 1;
            END_IF;
        END_IF;
    END_IF;

    GVL_TIME_SERVICE.G_Now_MS := GVL_TIME_SERVICE.G_Sim_Now_MS;
    GVL_TIME_SERVICE.G_Time_Of_Day_MS := GVL_TIME_SERVICE.G_Sim_Time_Of_Day_MS;
    GVL_TIME_SERVICE.G_Day_Of_Week := GVL_TIME_SERVICE.G_Sim_Day_Of_Week;

ELSE
    GVL_TIME_SERVICE.G_Now_MS := L_Real_Now;
    GVL_TIME_SERVICE.G_Time_Of_Day_MS := GVL_STATUS.G_Time_Of_Day_MS;
    GVL_TIME_SERVICE.G_Day_Of_Week := TO_INT(GVL_STATUS.G_Current_Day);
END_IF;

// TOD unified
GVL_TIME_SERVICE.G_Current_TOD := UDINT_TO_TOD(GVL_TIME_SERVICE.G_Time_Of_Day_MS);

GVL_TIME_SERVICE.G_Delta_MS := L_Elapsed;

END_FUNCTION_BLOCK
