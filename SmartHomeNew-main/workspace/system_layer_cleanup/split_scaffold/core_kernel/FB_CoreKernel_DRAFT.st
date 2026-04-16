FUNCTION_BLOCK FB_CoreKernel_DRAFT
VAR_INPUT
    VI_System_Time_MS : UDINT;
    VI_IsActivePLC : BOOL;
    VI_Legacy_Path_Ready : BOOL;
END_VAR
VAR_OUTPUT
    VO_Path_Ready : BOOL;
    VO_Shadow_Path_Ready : BOOL;
    VO_Diff_Found : BOOL;
END_VAR
VAR
    fbComparisonFlags : FB_CoreKernel_Comparison_Flags_DRAFT;
    L_Core_Path_Ready_Internal : BOOL;
    fbShadowOutputs : FB_CoreKernel_Shadow_Outputs_DRAFT;
    // Planned internal sub-blocks from PRG_System:
    fbRedundancySlice : FB_Redundancy_Shadow_Slice_DRAFT;
    fbSafetySlice : FB_Safety_Shadow_Slice_DRAFT;
    // - fbSafety
    fbWatchdogSlice : FB_Watchdog_Shadow_Slice_DRAFT;
    // - fbWatchdog
    fbSystemHealthSlice : FB_SystemHealth_Shadow_Slice_DRAFT;
    // - fbSystemHealth
    fbStateManagerSlice : FB_StateManager_Shadow_Slice_DRAFT;
    // - fbStateManager
END_VAR

// Redundancy shadow slice execution
fbRedundancySlice(
    VI_System_Time_MS := VI_System_Time_MS,
    VI_Enable := VI_IsActivePLC,
    VO_Shadow_Ready => L_Core_Path_Ready_Internal
);

// Safety shadow slice execution
fbSafetySlice(
    VI_System_Time_MS := VI_System_Time_MS,
    VI_Enable := VI_IsActivePLC,
    VO_Shadow_Ready => L_Core_Path_Ready_Internal
);

// Watchdog shadow slice execution
fbWatchdogSlice(
    VI_System_Time_MS := VI_System_Time_MS,
    VI_Enable := VI_IsActivePLC,
    VO_Shadow_Ready => L_Core_Path_Ready_Internal
);

// SystemHealth shadow slice execution
fbSystemHealthSlice(
    VI_System_Time_MS := VI_System_Time_MS,
    VI_Enable := VI_IsActivePLC,
    VO_Shadow_Ready => L_Core_Path_Ready_Internal
);

// StateManager shadow slice execution
fbStateManagerSlice(
    VI_System_Time_MS := VI_System_Time_MS,
    VI_Enable := VI_IsActivePLC,
    VO_Shadow_Ready => L_Core_Path_Ready_Internal
);


// Shadow outputs projection
VO_Path_Ready := L_Core_Path_Ready_Internal;
fbShadowOutputs(
    VI_Shadow_Path_Ready := L_Core_Path_Ready_Internal,
    VO_Shadow_Path_Ready => VO_Shadow_Path_Ready
);


// CoreKernel comparison flags
// NOTE: comparison must use external legacy input, not mirrored core output.
fbComparisonFlags(
    VI_IsActivePLC := VI_IsActivePLC,
    VI_Legacy_Path_Ready := VI_Legacy_Path_Ready,
    VI_Shadow_Path_Ready := VO_Shadow_Path_Ready,
    VO_Diff_Found => VO_Diff_Found
);

END_FUNCTION_BLOCK
