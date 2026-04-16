FUNCTION_BLOCK FB_CoreKernel_Comparison_Harness_DRAFT
VAR_INPUT
    VI_System_Time_MS : UDINT;
    VI_IsActivePLC : BOOL;
    VI_Legacy_Path_Ready : BOOL;
END_VAR
VAR_OUTPUT
    VO_Shadow_Path_Ready : BOOL;
    VO_Diff_Found : BOOL;
END_VAR
VAR
    fbCoreKernel : FB_CoreKernel_DRAFT;
    L_Path_Ready : BOOL;
END_VAR

fbCoreKernel(
    VI_System_Time_MS := VI_System_Time_MS,
    VI_IsActivePLC := VI_IsActivePLC,
    VI_Legacy_Path_Ready := VI_Legacy_Path_Ready,
    VO_Path_Ready => L_Path_Ready,
    VO_Shadow_Path_Ready => VO_Shadow_Path_Ready,
    VO_Diff_Found => VO_Diff_Found
);

END_FUNCTION_BLOCK
