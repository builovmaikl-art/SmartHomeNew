PROGRAM PRG_System_Health
VAR
    fbSystemHealthOrchestrator : FB_System_Health_Orchestrator;
END_VAR

// Centralized Health execution (Phase 5)
fbSystemHealthOrchestrator(
    VO_First_Fault_Active => GVL_SYSTEM_HEALTH.G_First_Fault_Active,
    VO_First_Fault_Type => GVL_SYSTEM_HEALTH.G_First_Fault_Type,
    VO_First_Fault_Source => GVL_SYSTEM_HEALTH.G_First_Fault_Source,
    VO_System_Severity => GVL_SYSTEM_HEALTH.G_System_Severity,
    VO_Root_Cause => GVL_SYSTEM_HEALTH.G_Root_Cause,
    VO_Watchdog_Fault => GVL_SYSTEM_HEALTH.G_Watchdog_Fault
);

END_PROGRAM
