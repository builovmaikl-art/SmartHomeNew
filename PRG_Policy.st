PROGRAM PRG_Policy
VAR
END_VAR

// Scenario policy owner (foundation)
// Priority: Safety > Gateway > Rule > keep current

IF GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_SAFE_STOP THEN
    GVL_POLICY.G_Scenario_Intent := E_SCENARIO_TYPE.SCENARIO_NONE;
    GVL_POLICY.G_Scenario_Source := SRC_SAFETY;

ELSIF GVL_POLICY.G_Scenario_Request_Gateway <> E_SCENARIO_TYPE.SCENARIO_NONE THEN
    GVL_POLICY.G_Scenario_Intent := GVL_POLICY.G_Scenario_Request_Gateway;
    GVL_POLICY.G_Scenario_Source := SRC_GATEWAY;

ELSIF GVL_POLICY.G_Scenario_Request_Rule <> E_SCENARIO_TYPE.SCENARIO_NONE THEN
    GVL_POLICY.G_Scenario_Intent := GVL_POLICY.G_Scenario_Request_Rule;
    GVL_POLICY.G_Scenario_Source := SRC_RULE;

ELSE
    GVL_POLICY.G_Scenario_Intent := GVL_STATUS.G_Current_Scenario;
    GVL_POLICY.G_Scenario_Source := SRC_NONE;
END_IF;

// Heating request bridge
GVL_STATE.G_Preheat_Request := GVL_POLICY.G_Rule_Preheat_Request;
GVL_STATE.G_Freeze_Request := (GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_FREEZE_PROTECTION);
