PROGRAM PRG_System_Scenario_Rules
VAR
    fbSystemScenarioArb : FB_System_Scenario_Arbitration;
    fbRuleEngine : FB_Rule_Engine;
    L_i : INT;
    L_Scenario_Req_Operator : E_SCENARIO_TYPE;
    L_Scenario_Req_Gateway  : E_SCENARIO_TYPE;
    L_Scenario_Req_Rule     : E_SCENARIO_TYPE;
    L_Scenario_Req_Final    : E_SCENARIO_TYPE;
    L_Scenario_Intent       : E_SCENARIO_TYPE;
    L_Scenario_Source       : E_SCENARIO_SOURCE;
    L_Best_Rule_Priority    : BYTE;
    L_Rule_Scenario_Code    : INT;

    // adapters
    L_Motion_16 : ARRAY[1..16] OF BOOL;
END_VAR

// adapt motion sensors (32 -> 16)
FOR L_i := 1 TO 16 DO
    L_Motion_16[L_i] := GVL_STATE.G_Motion_Sensors[L_i];
END_FOR;

IF GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_NORMAL THEN
    L_Scenario_Req_Operator := GVL_COMMAND.G_Scenario_Request_Operator;
ELSE
    L_Scenario_Req_Operator := E_SCENARIO_TYPE.SCENARIO_NONE;
END_IF;

L_Scenario_Req_Gateway := GVL_INTENT_USER.I_Scenario_Request;
L_Scenario_Req_Rule := E_SCENARIO_TYPE.SCENARIO_NONE;
L_Best_Rule_Priority := 0;
GVL_POLICY.G_Rule_Preheat_Request := FALSE;
GVL_POLICY.G_Scenario_Request_Rule := E_SCENARIO_TYPE.SCENARIO_NONE;

fbRuleEngine(
    VI_System_Time_MS := GVL_TIME_SERVICE.G_Now_MS,
    VI_IsActivePLC := GVL_STATUS.G_Is_Active_PLC,
    VI_Security_Armed := GVL_ALARM.G_Security_Armed,
    VI_Current_Time := GVL_TIME_SERVICE.G_Current_TOD,
    VI_Day_Of_Week := GVL_TIME_SERVICE.G_Day_Of_Week,
    VI_Rules := GVL_CONFIG.G_HMI_User_Rules,
    VI_Indoor_Temps := GVL_STATE.G_Room_Temps,
    VI_Floor_Temps := GVL_STATE.G_Floor_Temps,
    VI_Humidities := GVL_STATE.G_Room_Hum,
    VI_CO2_Levels := GVL_STATE.G_Room_CO2,
    VI_Motion_Sensors := L_Motion_16,
    VI_Door_Sensors := GVL_STATE.G_Door_Sensors,
    VI_Window_Sensors := GVL_STATE.G_Window_Sensors,
    VI_Water_Sensors := GVL_STATE.G_Water_Sensors,
    VI_Smoke_Sensors := GVL_STATE.G_Smoke_Sensors,
    VI_Methane_Sensors := GVL_STATE.G_Methane_Sensors,
    VI_CO_Sensors := GVL_STATE.G_CO_Sensors,
    VO_Preheat_Request => GVL_POLICY.G_Rule_Preheat_Request,
    VO_Actions => GVL_STATE.G_Rule_Actions
);

// Scenario actions are bridged into policy/scenario arbitration. If several
// scenario rules are active, the highest rule Priority wins. Operator and
// gateway requests still outrank rule requests in FB_System_Scenario_Arbitration.
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_RULES DO
    IF GVL_STATE.G_Rule_Actions[L_i].Active AND
       (GVL_STATE.G_Rule_Actions[L_i].Action_Type = E_Rule_Action_Type.ACTION_ACTIVATE_SCENARIO) THEN

        L_Rule_Scenario_Code := REAL_TO_INT(GVL_STATE.G_Rule_Actions[L_i].Value);

        IF (L_Rule_Scenario_Code >= 0) AND (L_Rule_Scenario_Code <= 7) AND
           ((L_Scenario_Req_Rule = E_SCENARIO_TYPE.SCENARIO_NONE) OR
            (GVL_CONFIG.G_HMI_User_Rules[L_i].Priority >= L_Best_Rule_Priority)) THEN

            L_Best_Rule_Priority := GVL_CONFIG.G_HMI_User_Rules[L_i].Priority;

            CASE L_Rule_Scenario_Code OF
                0:
                    L_Scenario_Req_Rule := E_SCENARIO_TYPE.SCENARIO_NONE;
                1:
                    L_Scenario_Req_Rule := E_SCENARIO_TYPE.SCENARIO_MORNING;
                2:
                    L_Scenario_Req_Rule := E_SCENARIO_TYPE.SCENARIO_EVENING;
                3:
                    L_Scenario_Req_Rule := E_SCENARIO_TYPE.SCENARIO_AWAY;
                4:
                    L_Scenario_Req_Rule := E_SCENARIO_TYPE.SCENARIO_PARTY;
                5:
                    L_Scenario_Req_Rule := E_SCENARIO_TYPE.SCENARIO_SLEEP;
                6:
                    L_Scenario_Req_Rule := E_SCENARIO_TYPE.SCENARIO_EMERGENCY;
                7:
                    L_Scenario_Req_Rule := E_SCENARIO_TYPE.SCENARIO_PRESENCE;
            ELSE
                    L_Scenario_Req_Rule := E_SCENARIO_TYPE.SCENARIO_NONE;
            END_CASE;
        END_IF;
    END_IF;
END_FOR;

GVL_POLICY.G_Scenario_Request_Rule := L_Scenario_Req_Rule;

fbSystemScenarioArb(
    VI_System_Time_MS := GVL_TIME_SERVICE.G_Now_MS,
    VI_IsActivePLC := GVL_STATUS.G_Is_Active_PLC,
    VI_System_Mode := GVL_STATE.G_System_Mode,
    VI_Security_Armed := GVL_ALARM.G_Security_Armed,
    VIO_Scenario_Req_Operator := L_Scenario_Req_Operator,
    VIO_Scenario_Req_Gateway := L_Scenario_Req_Gateway,
    VIO_Scenario_Req_Rule := L_Scenario_Req_Rule,
    VIO_Scenario_Req_Final := L_Scenario_Req_Final,
    VIO_Scenario_Intent := L_Scenario_Intent,
    VIO_Scenario_Source := L_Scenario_Source
);

GVL_POLICY.G_Scenario_Intent := L_Scenario_Intent;
GVL_POLICY.G_Scenario_Source := L_Scenario_Source;

END_PROGRAM