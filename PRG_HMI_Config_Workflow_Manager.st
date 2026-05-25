PROGRAM PRG_HMI_Config_Workflow_Manager
// ==============================================================================
// HMI CONFIG WORKFLOW MANAGER — runtime bridge for operator config workflow.
// ==============================================================================
// Runs the existing HMI workflow/runtime activation FBs. The workflow FB validates
// service/ack conditions and publishes requests into config-control surfaces.
// ==============================================================================
VAR
    fbHMIConfigWorkflow : FB_HMI_Config_Workflow_Runtime;
    fbConfigActivation : FB_Config_Activation_Runtime;
END_VAR

fbHMIConfigWorkflow(
    VI_Enable := TRUE,
    VI_System_Time_MS := GVL_TIME_SERVICE.G_Now_MS
);

fbConfigActivation(
    VI_Enable := TRUE,
    VI_System_Time_MS := GVL_TIME_SERVICE.G_Now_MS
);

// >>> BULK_SYNC_ANCHOR: PRG_HMI_Config_Workflow_Manager <<<
END_PROGRAM
