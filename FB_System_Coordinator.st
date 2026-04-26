FUNCTION_BLOCK FB_System_Coordinator

VAR_INPUT
    VI_Fire_Latched : BOOL;
    VI_Gas_Latched : BOOL;
    VI_Leak_Latched : BOOL;

    VI_IO_Degraded : BOOL;
    VI_Ownership_Violation : BOOL;
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

// FIRE
IF VI_Fire_Latched THEN
    VO_Block_Heating := TRUE;
    VO_Block_Ventilation := TRUE;
    VO_Block_Sockets := TRUE;
    VO_Code := 100;
    RETURN;
END_IF;

// GAS
IF VI_Gas_Latched THEN
    VO_Block_Heating := TRUE;
    VO_Block_Lighting := TRUE;
    VO_Block_Sockets := TRUE;
    VO_Code := 200;
    RETURN;
END_IF;

// LEAK
IF VI_Leak_Latched THEN
    VO_Block_Heating := TRUE;
    VO_Code := 300;
END_IF;

// IO degraded
IF VI_IO_Degraded THEN
    VO_System_Degraded := TRUE;
    VO_Block_Heating := TRUE;
    VO_Code := 400;
END_IF;

// ownership violation
IF VI_Ownership_Violation THEN
    VO_System_Degraded := TRUE;
    VO_Code := 500;
END_IF;
