PROGRAM PRG_HMI_Config_Workflow_Manager
// ==============================================================================
// HMI CONFIG WORKFLOW MANAGER — runtime bridge for operator config workflow.
// ==============================================================================
// Runs config activation, HMI workflow and staged-config simulation. The activation
// FB refreshes staged topology state first; the workflow FB publishes simulation
// and config-control requests; simulation then consumes validation requests.
// A final workflow refresh publishes same-scan validation pass/fail status to HMI.
// ==============================================================================
VAR
    fbHMIConfigWorkflow : FB_HMI_Config_Workflow_Runtime;
    fbConfigActivation : FB_Config_Activation_Runtime;
    fbConfigSimulation : FB_Config_Simulation;
END_VAR

fbConfigActivation(
    VI_Enable := TRUE,
    VI_System_Time_MS := GVL_TIME_SERVICE.G_Now_MS
);

fbHMIConfigWorkflow(
    VI_Enable := TRUE,
    VI_System_Time_MS := GVL_TIME_SERVICE.G_Now_MS
);

fbConfigSimulation(
    VI_Enable := TRUE,
    VI_Request := GVL_CONFIG_SIMULATION.G_Simulation_Request,
    VI_Confirm := GVL_CONFIG_SIMULATION.G_Simulation_Confirm
);

fbHMIConfigWorkflow(
    VI_Enable := TRUE,
    VI_System_Time_MS := GVL_TIME_SERVICE.G_Now_MS
);

// >>> BULK_SYNC_ANCHOR: PRG_HMI_Config_Workflow_Manager <<<
END_PROGRAM
