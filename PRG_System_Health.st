PROGRAM PRG_System_Health
VAR
    fbSystemHealthOrchestrator : FB_System_Health_Orchestrator;
    L_First_Fault_Active : BOOL;
    L_First_Fault_Type : INT;
    L_First_Fault_Source : INT;
    L_System_Severity : E_System_Severity;
    L_Root_Cause : E_System_Root_Cause;
    L_Watchdog_Fault : BOOL;
END_VAR

// Extracted health/state aggregation contour (Phase 5B).
// DO NOT connect in MAIN while legacy PRG_System still calls the same FB.
// Reason: FB_System_Health_Orchestrator writes GVL_STATE/GVL_STATUS/GVL_GATEWAY.

fbSystemHealthOrchestrator(
    VO_First_Fault_Active => L_First_Fault_Active,
    VO_First_Fault_Type => L_First_Fault_Type,
    VO_First_Fault_Source => L_First_Fault_Source,
    VO_System_Severity => L_System_Severity,
    VO_Root_Cause => L_Root_Cause,
    VO_Watchdog_Fault => L_Watchdog_Fault
);

END_PROGRAM
