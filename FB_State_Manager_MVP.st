FUNCTION_BLOCK FB_State_Manager
VAR_INPUT
    VI_Gas_Alarm     : BOOL;
    VI_Fire_Alarm    : BOOL;
    VI_Flood_Alarm   : BOOL;

    VI_IO_Healthy    : BOOL;
    VI_Freeze_Risk   : BOOL;

    VI_Reset_Request : BOOL;
END_VAR

VAR_OUTPUT
    VO_System_Mode : INT; // temporary, replace with ENUM later
END_VAR

VAR
    L_Fire_Latched  : BOOL;
    L_Gas_Latched   : BOOL;
    L_Flood_Latched : BOOL;
END_VAR

// Fire latch
IF VI_Fire_Alarm THEN
    L_Fire_Latched := TRUE;
END_IF;
IF VI_Reset_Request AND NOT VI_Fire_Alarm THEN
    L_Fire_Latched := FALSE;
END_IF;

// Gas latch
IF VI_Gas_Alarm THEN
    L_Gas_Latched := TRUE;
END_IF;
IF VI_Reset_Request AND NOT VI_Gas_Alarm THEN
    L_Gas_Latched := FALSE;
END_IF;

// Flood latch
IF VI_Flood_Alarm THEN
    L_Flood_Latched := TRUE;
END_IF;
IF VI_Reset_Request AND NOT VI_Flood_Alarm THEN
    L_Flood_Latched := FALSE;
END_IF;

// Mode logic
IF L_Fire_Latched THEN
    VO_System_Mode := 2; // SAFE_STOP
ELSIF L_Flood_Latched THEN
    VO_System_Mode := 2;
ELSIF L_Gas_Latched THEN
    IF VI_Freeze_Risk THEN
        VO_System_Mode := 3; // FREEZE
    ELSE
        VO_System_Mode := 1; // DEGRADED
    END_IF;
ELSIF NOT VI_IO_Healthy THEN
    VO_System_Mode := 1;
ELSE
    VO_System_Mode := 0; // NORMAL
END_IF;
