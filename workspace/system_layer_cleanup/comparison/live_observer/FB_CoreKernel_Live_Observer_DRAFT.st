FUNCTION_BLOCK FB_CoreKernel_Live_Observer_DRAFT
VAR_INPUT
    VI_System_Time_MS : UDINT;
END_VAR
VAR_OUTPUT
    VO_Shadow_Path_Ready : BOOL;
    VO_Diff_Found : BOOL;
END_VAR
VAR
    fbBinding : FB_CoreKernel_First_Live_Binding_DRAFT;
END_VAR

fbBinding(
    VI_System_Time_MS := VI_System_Time_MS,
    VO_Shadow_Path_Ready => VO_Shadow_Path_Ready,
    VO_Diff_Found => VO_Diff_Found
);

END_FUNCTION_BLOCK
