FUNCTION_BLOCK FB_CoreKernel_Shadow_Stub_DRAFT
VAR_INPUT
    VI_System_Time_MS : UDINT;
    VI_IsActivePLC : BOOL;
END_VAR
VAR_OUTPUT
    VO_Shadow_Ready : BOOL;
END_VAR
VAR
    fbCoreKernel : FB_CoreKernel_DRAFT;
END_VAR

fbCoreKernel(
    VI_System_Time_MS := VI_System_Time_MS,
    VI_IsActivePLC := VI_IsActivePLC,
    VO_Path_Ready => VO_Shadow_Ready
);

END_FUNCTION_BLOCK
