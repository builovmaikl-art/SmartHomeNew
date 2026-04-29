// ==============================================================================
// System scenario arbitration helper
//
// Internal helper for PRG_System.
// Owns scenario request validation, priority resolution, fail-safe clamp,
// degraded-mode adaptation, policy logging, and FB_Scenario_Manager call.
// ==============================================================================
FUNCTION_BLOCK FB_System_Scenario_Arbitration
VAR_INPUT
    VI_System_Time_MS : UDINT;
    VI_IsActivePLC : BOOL;
    VI_System_Mode : E_System_Operating_Mode;
    VI_Security_Armed : BOOL;
END_VAR

VAR_IN_OUT
    VIO_Scenario_Req_Operator : E_SCENARIO_TYPE;
    VIO_Scenario_Req_Gateway : E_SCENARIO_TYPE;
    VIO_Scenario_Req_Rule : E_SCENARIO_TYPE;
    VIO_Scenario_Req_Final : E_SCENARIO_TYPE;
    VIO_Scenario_Intent : E_SCENARIO_TYPE;
    VIO_Scenario_Source : E_SCENARIO_SOURCE;
END_VAR

VAR
    fbLogEvent : FB_LogEvent;
    fbScenarioManager : FB_Scenario_Manager;
END_VAR

// === SCENARIO REQUEST VALIDATION ===
// Normalize invalid values to NONE to avoid corrupt inputs.
// Actual enum range in E_SCENARIO_TYPE is 0..7.
IF TO_USINT(VIO_Scenario_Req_Operator) > 7 THEN
    VIO_Scenario_Req_Operator := E_SCENARIO_TYPE.SCENARIO_NONE;
END_IF;

IF TO_USINT(VIO_Scenario_Req_Gateway) > 7 THEN
    VIO_Scenario_Req_Gateway := E_SCENARIO_TYPE.SCENARIO_NONE;
END_IF;

IF TO_USINT(VIO_Scenario_Req_Rule) > 7 THEN
    VIO_Scenario_Req_Rule := E_SCENARIO_TYPE.SCENARIO_NONE;
END_IF;

// === SCENARIO PRIORITY RESOLUTION ===
// Produces VIO_Scenario_Req_Final (TRACE ONLY, not executed directly)
IF VI_System_Mode = E_System_Operating_Mode.MODE_SAFE_STOP THEN
    VIO_Scenario_Req_Final := 0;
    VIO_Scenario_Source := SRC_SAFETY;
ELSIF VIO_Scenario_Req_Operator <> 0 THEN
    VIO_Scenario_Req_Final := VIO_Scenario_Req_Operator;
    VIO_Scenario_Source := SRC_OPERATOR;
ELSIF VIO_Scenario_Req_Gateway <> 0 THEN
    VIO_Scenario_Req_Final := VIO_Scenario_Req_Gateway;
    VIO_Scenario_Source := SRC_GATEWAY;
ELSIF VIO_Scenario_Req_Rule <> 0 THEN
    VIO_Scenario_Req_Final := VIO_Scenario_Req_Rule;
    VIO_Scenario_Source := SRC_RULE;
ELSE
    VIO_Scenario_Req_Final := GVL_STATUS.G_Current_Scenario;
    VIO_Scenario_Source := SRC_NONE;
END_IF;

VIO_Scenario_Intent := VIO_Scenario_Req_Final;

// === FAIL-SAFE SCENARIO CLAMP ===
CASE VI_System_Mode OF
    E_System_Operating_Mode.MODE_SAFE_STOP:
        VIO_Scenario_Intent := E_SCENARIO_TYPE.SCENARIO_NONE;

    E_System_Operating_Mode.MODE_FREEZE_PROTECTION:
        VIO_Scenario_Intent := E_SCENARIO_TYPE.SCENARIO_NONE;

    E_System_Operating_Mode.MODE_DEGRADED:
        CASE VIO_Scenario_Intent OF
            E_SCENARIO_TYPE.SCENARIO_NONE,
            E_SCENARIO_TYPE.SCENARIO_PRESENCE,
            E_SCENARIO_TYPE.SCENARIO_AWAY,
            E_SCENARIO_TYPE.SCENARIO_SLEEP:
                ; // allowed in degraded
        ELSE
            VIO_Scenario_Intent := E_SCENARIO_TYPE.SCENARIO_NONE;
        END_CASE;
END_CASE;

// === CONTEXT FAIL-SAFE AUTOMATION ===
// If security is armed and no explicit source is requesting another scenario,
// force safe occupancy context to AWAY while system remains in MODE_NORMAL.
IF VI_System_Mode = E_System_Operating_Mode.MODE_NORMAL THEN
    IF VI_Security_Armed AND
       (VIO_Scenario_Req_Operator = E_SCENARIO_TYPE.SCENARIO_NONE) AND
       (VIO_Scenario_Req_Gateway = E_SCENARIO_TYPE.SCENARIO_NONE) AND
       (VIO_Scenario_Req_Rule = E_SCENARIO_TYPE.SCENARIO_NONE) AND
       (VIO_Scenario_Intent <> E_SCENARIO_TYPE.SCENARIO_AWAY) THEN

        IF VIO_Scenario_Intent <> E_SCENARIO_TYPE.SCENARIO_AWAY THEN
            VIO_Scenario_Intent := E_SCENARIO_TYPE.SCENARIO_AWAY;
            VIO_Scenario_Source := SRC_POLICY;

            fbLogEvent(
                VI_Event_Type := 5,
                VI_Timestamp := VI_System_Time_MS,
                VI_Param1 := TO_UDINT(VIO_Scenario_Source),
                VI_Param2 := TO_UDINT(E_SCENARIO_TYPE.SCENARIO_AWAY)
            );
        END_IF;
    END_IF;
END_IF;

// === DEGRADED-AWARE SCENARIO ADAPTATION ===
// Soft adaptation in degraded mode: keep explicit requests intact,
// but if no source is requesting a scenario, move behavior to a safer baseline.
IF VI_System_Mode = E_System_Operating_Mode.MODE_DEGRADED THEN
    IF (VIO_Scenario_Req_Operator = E_SCENARIO_TYPE.SCENARIO_NONE) AND
       (VIO_Scenario_Req_Gateway = E_SCENARIO_TYPE.SCENARIO_NONE) AND
       (VIO_Scenario_Req_Rule = E_SCENARIO_TYPE.SCENARIO_NONE) THEN

        IF VI_Security_Armed THEN
            IF VIO_Scenario_Intent <> E_SCENARIO_TYPE.SCENARIO_AWAY THEN
                VIO_Scenario_Intent := E_SCENARIO_TYPE.SCENARIO_AWAY;
                VIO_Scenario_Source := SRC_POLICY;

                fbLogEvent(
                    VI_Event_Type := 6,
                    VI_Timestamp := VI_System_Time_MS,
                    VI_Param1 := TO_UDINT(VIO_Scenario_Source),
                    VI_Param2 := TO_UDINT(E_SCENARIO_TYPE.SCENARIO_AWAY)
                );
            END_IF;

        ELSIF VIO_Scenario_Intent = E_SCENARIO_TYPE.SCENARIO_PRESENCE THEN
            IF VIO_Scenario_Intent <> E_SCENARIO_TYPE.SCENARIO_SLEEP THEN
                VIO_Scenario_Intent := E_SCENARIO_TYPE.SCENARIO_SLEEP;
                VIO_Scenario_Source := SRC_POLICY;

                fbLogEvent(
                    VI_Event_Type := 7,
                    VI_Timestamp := VI_System_Time_MS,
                    VI_Param1 := TO_UDINT(VIO_Scenario_Source),
                    VI_Param2 := TO_UDINT(E_SCENARIO_TYPE.SCENARIO_SLEEP)
                );
            END_IF;
        END_IF;
    END_IF;
END_IF;

fbScenarioManager(
    VI_System_Time_MS := VI_System_Time_MS,
    VI_Activate_Request := VIO_Scenario_Intent,
    VI_IsActivePLC := VI_IsActivePLC,
    VI_System_Mode := VI_System_Mode,
    VO_Current_Scenario => GVL_STATUS.G_Current_Scenario
);

// >>> BULK_SYNC_ANCHOR: FB_System_Scenario_Arbitration <<<
