FUNCTION_BLOCK FB_Time_Service
VAR
    L_Now : UDINT;
END_VAR

// read raw time
L_Now := GVL_STATUS.G_System_Time_MS;

// wrap-safe delta
IF L_Now >= GVL_TIME_SERVICE.G_Last_Now_MS THEN
    GVL_TIME_SERVICE.G_Delta_MS := L_Now - GVL_TIME_SERVICE.G_Last_Now_MS;
    GVL_TIME_SERVICE.G_Wrap_Detected := FALSE;
ELSE
    GVL_TIME_SERVICE.G_Delta_MS := (16#FFFFFFFF - GVL_TIME_SERVICE.G_Last_Now_MS) + L_Now + 1;
    GVL_TIME_SERVICE.G_Wrap_Detected := TRUE;
END_IF;

// publish normalized time
GVL_TIME_SERVICE.G_Now_MS := L_Now;
GVL_TIME_SERVICE.G_Time_Of_Day_MS := GVL_STATUS.G_Time_Of_Day_MS;
GVL_TIME_SERVICE.G_Day_Of_Week := INT(GVL_STATUS.G_Current_Day);

GVL_TIME_SERVICE.G_Last_Now_MS := L_Now;

END_FUNCTION_BLOCK
