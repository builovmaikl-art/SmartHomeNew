PROGRAM PRG_Policy
VAR
END_VAR

// ============================================================
// SCENARIO POLICY OWNER
// ============================================================

// 1. Base priority resolution
IF GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_SAFE_STOP THEN
    GVL_POLICY.G_Scenario_Intent := E_SCENARIO_TYPE.SCENARIO_NONE;
    GVL_POLICY.G_Scenario_Source := SRC_SAFETY;

ELSIF GVL_POLICY.G_Scenario_Request_Operator <> E_SCENARIO_TYPE.SCENARIO_NONE THEN
    GVL_POLICY.G_Scenario_Intent := GVL_POLICY.G_Scenario_Request_Operator;
    GVL_POLICY.G_Scenario_Source := SRC_OPERATOR;

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

// 2. Fail-safe clamp
CASE GVL_STATE.G_System_Mode OF
    E_System_Operating_Mode.MODE_SAFE_STOP:
        GVL_POLICY.G_Scenario_Intent := E_SCENARIO_TYPE.SCENARIO_NONE;
        GVL_POLICY.G_Scenario_Source := SRC_SAFETY;

    E_System_Operating_Mode.MODE_FREEZE_PROTECTION:
        GVL_POLICY.G_Scenario_Intent := E_SCENARIO_TYPE.SCENARIO_NONE;
        GVL_POLICY.G_Scenario_Source := SRC_POLICY;

    E_System_Operating_Mode.MODE_DEGRADED:
        CASE GVL_POLICY.G_Scenario_Intent OF
            E_SCENARIO_TYPE.SCENARIO_NONE,
            E_SCENARIO_TYPE.SCENARIO_PRESENCE,
            E_SCENARIO_TYPE.SCENARIO_AWAY,
            E_SCENARIO_TYPE.SCENARIO_SLEEP:
                ;
        ELSE
            GVL_POLICY.G_Scenario_Intent := E_SCENARIO_TYPE.SCENARIO_NONE;
            GVL_POLICY.G_Scenario_Source := SRC_POLICY;
        END_CASE;
END_CASE;

// 3. Context automation
IF GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_NORMAL THEN
    IF GVL_ALARM.G_Security_Armed AND
       (GVL_POLICY.G_Scenario_Request_Operator = E_SCENARIO_TYPE.SCENARIO_NONE) AND
       (GVL_POLICY.G_Scenario_Request_Gateway = E_SCENARIO_TYPE.SCENARIO_NONE) AND
       (GVL_POLICY.G_Scenario_Request_Rule = E_SCENARIO_TYPE.SCENARIO_NONE) AND
       (GVL_POLICY.G_Scenario_Intent <> E_SCENARIO_TYPE.SCENARIO_AWAY) THEN
        GVL_POLICY.G_Scenario_Intent := E_SCENARIO_TYPE.SCENARIO_AWAY;
        GVL_POLICY.G_Scenario_Source := SRC_POLICY;
    END_IF;
END_IF;

// 4. Degraded adaptation
IF GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_DEGRADED THEN
    IF (GVL_POLICY.G_Scenario_Request_Operator = E_SCENARIO_TYPE.SCENARIO_NONE) AND
       (GVL_POLICY.G_Scenario_Request_Gateway = E_SCENARIO_TYPE.SCENARIO_NONE) AND
       (GVL_POLICY.G_Scenario_Request_Rule = E_SCENARIO_TYPE.SCENARIO_NONE) THEN

        IF GVL_ALARM.G_Security_Armed THEN
            GVL_POLICY.G_Scenario_Intent := E_SCENARIO_TYPE.SCENARIO_AWAY;
            GVL_POLICY.G_Scenario_Source := SRC_POLICY;

        ELSIF GVL_POLICY.G_Scenario_Intent = E_SCENARIO_TYPE.SCENARIO_PRESENCE THEN
            GVL_POLICY.G_Scenario_Intent := E_SCENARIO_TYPE.SCENARIO_SLEEP;
            GVL_POLICY.G_Scenario_Source := SRC_POLICY;
        END_IF;
    END_IF;
END_IF;

// 5. Heating bridge
GVL_STATE.G_Preheat_Request := GVL_POLICY.G_Rule_Preheat_Request;
GVL_STATE.G_Freeze_Request :=
    (GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_FREEZE_PROTECTION);
