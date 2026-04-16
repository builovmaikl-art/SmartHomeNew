FUNCTION_BLOCK FB_CoreKernel_First_Live_Binding_DRAFT
VAR_INPUT
    VI_System_Time_MS : UDINT;
END_VAR
VAR_OUTPUT
    VO_Shadow_Path_Ready : BOOL;
    VO_Diff_Found : BOOL;
END_VAR
VAR
    fbHarness : FB_CoreKernel_Comparison_Harness_DRAFT;
END_VAR

fbHarness(
    VI_System_Time_MS := VI_System_Time_MS,
    VI_IsActivePLC := GVL_STATUS.G_Is_Active_PLC,
    VI_Legacy_Path_Ready := GVL_STATUS.G_Is_Active_PLC,
    VO_Shadow_Path_Ready => VO_Shadow_Path_Ready,
    VO_Diff_Found => VO_Diff_Found
);

END_FUNCTION_BLOCK
