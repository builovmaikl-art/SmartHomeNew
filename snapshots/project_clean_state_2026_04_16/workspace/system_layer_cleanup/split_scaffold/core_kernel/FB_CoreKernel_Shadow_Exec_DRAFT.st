FUNCTION_BLOCK FB_CoreKernel_Shadow_Exec_DRAFT
VAR_INPUT
    VI_System_Time_MS : UDINT;
    VI_IsActivePLC : BOOL;
END_VAR
VAR_OUTPUT
    VO_Shadow_Path_Ready : BOOL;
END_VAR
VAR
    fbCoreKernelShadow : FB_CoreKernel_Shadow_Stub_DRAFT;
END_VAR

fbCoreKernelShadow(
    VI_System_Time_MS := VI_System_Time_MS,
    VI_IsActivePLC := VI_IsActivePLC,
    VO_Shadow_Ready => VO_Shadow_Path_Ready
);

END_FUNCTION_BLOCK
