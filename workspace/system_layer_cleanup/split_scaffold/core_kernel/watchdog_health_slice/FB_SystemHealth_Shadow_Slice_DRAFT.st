FUNCTION_BLOCK FB_SystemHealth_Shadow_Slice_DRAFT
VAR_INPUT
    VI_System_Time_MS : UDINT;
    VI_Enable : BOOL;
END_VAR
VAR_OUTPUT
    VO_Shadow_Ready : BOOL;
END_VAR
VAR
    // Future target:
    // fbSystemHealth : FB_System_Health;
END_VAR

VO_Shadow_Ready := VI_Enable;

END_FUNCTION_BLOCK
