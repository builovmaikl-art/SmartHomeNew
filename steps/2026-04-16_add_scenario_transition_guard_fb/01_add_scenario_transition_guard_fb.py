from pathlib import Path

target = Path("FB_Scenario_Transition_Guard.st")

content = """FUNCTION_BLOCK FB_Scenario_Transition_Guard
VAR_INPUT
    VI_Current_Scenario : E_SCENARIO_TYPE;
    VI_Target_Scenario  : E_SCENARIO_TYPE;
END_VAR

VAR_OUTPUT
    VO_Transition_Allowed : BOOL;
    VO_Reason             : STRING(120);
END_VAR

VO_Transition_Allowed := TRUE;
VO_Reason := 'OK';

// no-op transition is always allowed
IF VI_Current_Scenario = VI_Target_Scenario THEN
    RETURN;
END_IF;

// emergency can always be entered
IF VI_Target_Scenario = E_SCENARIO_TYPE.SCENARIO_EMERGENCY THEN
    RETURN;
END_IF;

// from NONE, any target is allowed
IF VI_Current_Scenario = E_SCENARIO_TYPE.SCENARIO_NONE THEN
    RETURN;
END_IF;

// emergency exit is restricted
IF VI_Current_Scenario = E_SCENARIO_TYPE.SCENARIO_EMERGENCY THEN
    CASE VI_Target_Scenario OF
        E_SCENARIO_TYPE.SCENARIO_NONE,
        E_SCENARIO_TYPE.SCENARIO_AWAY,
        E_SCENARIO_TYPE.SCENARIO_SLEEP,
        E_SCENARIO_TYPE.SCENARIO_PRESENCE:
            RETURN;
    ELSE
        VO_Transition_Allowed := FALSE;
        VO_Reason := 'Переход из EMERGENCY в данный сценарий запрещён';
        RETURN;
    END_CASE;
END_IF;

// away exit is restricted to safe occupancy contexts
IF VI_Current_Scenario = E_SCENARIO_TYPE.SCENARIO_AWAY THEN
    CASE VI_Target_Scenario OF
        E_SCENARIO_TYPE.SCENARIO_NONE,
        E_SCENARIO_TYPE.SCENARIO_SLEEP,
        E_SCENARIO_TYPE.SCENARIO_PRESENCE,
        E_SCENARIO_TYPE.SCENARIO_EMERGENCY:
            RETURN;
    ELSE
        VO_Transition_Allowed := FALSE;
        VO_Reason := 'Переход из AWAY в данный сценарий запрещён';
        RETURN;
    END_CASE;
END_IF;

// default: allow
RETURN;
// >>> BULK_SYNC_ANCHOR: FB_Scenario_Transition_Guard <<<
"""

target.write_text(content, encoding="utf-8")
print("OK: created FB_Scenario_Transition_Guard.st")
