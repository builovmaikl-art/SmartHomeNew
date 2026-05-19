PROGRAM PRG_System_Alarm_Gateway
VAR
    fbSystemAlarmOrchestrator : FB_System_Alarm_Orchestrator;
    fbSystemGatewayIntent : FB_System_Gateway_Intent;
    L_Scenario_Req_Gateway : E_SCENARIO_TYPE;
END_VAR

// Alarm orchestration based on global health snapshot
fbSystemAlarmOrchestrator(
    VI_First_Fault_Active := GVL_SYSTEM_HEALTH.G_First_Fault_Active,
    VI_First_Fault_Type := GVL_SYSTEM_HEALTH.G_First_Fault_Type,
    VI_First_Fault_Source := GVL_SYSTEM_HEALTH.G_First_Fault_Source
);

// Gateway intent execution
fbSystemGatewayIntent(
    VI_System_Time_MS := GVL_TIME_SERVICE.G_Now_MS,
    VI_IsActivePLC := GVL_STATUS.G_Is_Active_PLC,
    VI_Gateway_Writes_Allowed := NOT GVL_STATUS.G_Diagnostics.Operator_Action_Blocked,
    VIO_FloorHeating_Temps := GVL_STATE.G_Floor_Temps,
    VIO_Zone_Valve_States := GVL_STATE.G_Zone_Valves,
    VIO_Lighting_Base_Levels := GVL_STATE.G_Lighting_Levels,
    VIO_Scenario_Req_Gateway := L_Scenario_Req_Gateway
);

GVL_INTENT_USER.I_Scenario_Request := L_Scenario_Req_Gateway;

END_PROGRAM
