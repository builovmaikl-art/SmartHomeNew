FUNCTION_BLOCK FB_System_Coordinator

VAR_INPUT
    VI_Fire_Latched : BOOL;
    VI_Gas_Latched : BOOL;
    VI_Leak_Latched : BOOL;

    VI_IO_Degraded : BOOL;
    VI_Ownership_Violation : BOOL;

    VI_Behavior_Mode : E_Behavior_Mode;
END_VAR

VAR_OUTPUT
    VO_Block_Heating : BOOL;
    VO_Block_Ventilation : BOOL;
    VO_Block_Lighting : BOOL;
    VO_Block_Sockets : BOOL;

    VO_System_Degraded : BOOL;

    VO_Code : UDINT;
END_VAR

// reset
VO_Block_Heating := FALSE;
VO_Block_Ventilation := FALSE;
VO_Block_Lighting := FALSE;
VO_Block_Sockets := FALSE;
VO_System_Degraded := FALSE;
VO_Code := 0;

// FIRE has highest priority. Safety-stop ownership remains in PRG_Safety.
IF VI_Fire_Latched THEN
    VO_Block_Heating := TRUE;
    VO_Block_Ventilation := TRUE;
    VO_Block_Sockets := TRUE;
    VO_Code := 100;
    RETURN;
END_IF;

// GAS has higher priority than behavior mode.
IF VI_Gas_Latched THEN
    VO_Block_Heating := TRUE;
    VO_Block_Lighting := TRUE;
    VO_Block_Sockets := TRUE;
    VO_Code := 200;
    RETURN;
END_IF;

// LEAK blocks heating but does not suppress later degradation/mode overlays.
IF VI_Leak_Latched THEN
    VO_Block_Heating := TRUE;
    VO_Code := 300;
END_IF;

// IO degraded blocks heating and marks system degraded.
IF VI_IO_Degraded THEN
    VO_System_Degraded := TRUE;
    VO_Block_Heating := TRUE;
    IF VO_Code = 0 THEN
        VO_Code := 400;
    END_IF;
END_IF;

// Ownership violation marks system degraded. Test/result handler owns any safe-stop reaction.
IF VI_Ownership_Violation THEN
    VO_System_Degraded := TRUE;
    IF VO_Code = 0 THEN
        VO_Code := 500;
    END_IF;
END_IF;

// Behavior mode overlays. These are lower priority than safety/system faults.
CASE VI_Behavior_Mode OF
    BEHAVIOR_AWAY:
        VO_Block_Lighting := TRUE;
        VO_Block_Sockets := TRUE;
        IF VO_Code = 0 THEN
            VO_Code := 600;
        END_IF;

    BEHAVIOR_NIGHT:
        VO_Block_Lighting := TRUE;
        IF VO_Code = 0 THEN
            VO_Code := 700;
        END_IF;

    BEHAVIOR_MAINTENANCE:
        VO_Block_Heating := TRUE;
        VO_Block_Ventilation := TRUE;
        IF VO_Code = 0 THEN
            VO_Code := 800;
        END_IF;
END_CASE;
