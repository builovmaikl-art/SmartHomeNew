FUNCTION_BLOCK FB_CoreKernel_Comparison_Flags_DRAFT
VAR_INPUT
    VI_IsActivePLC : BOOL;
    VI_Legacy_Path_Ready : BOOL;
    VI_Shadow_Path_Ready : BOOL;
END_VAR
VAR_OUTPUT
    VO_Diff_Found : BOOL;
END_VAR

IF VI_IsActivePLC THEN
    VO_Diff_Found := (VI_Legacy_Path_Ready <> VI_Shadow_Path_Ready);
ELSE
    VO_Diff_Found := FALSE;
END_IF;

END_FUNCTION_BLOCK
