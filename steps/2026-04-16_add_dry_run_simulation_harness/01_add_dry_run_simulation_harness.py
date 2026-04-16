from pathlib import Path

target = Path("FB_DryRun_Simulation_Harness.st")

content = """FUNCTION_BLOCK FB_DryRun_Simulation_Harness
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
END_VAR

VAR_OUTPUT
    VO_Test_Step : INT;
    VO_Status_Msg : STRING(120);
    VO_Inject_Flood : BOOL;
    VO_Inject_Gas : BOOL;
    VO_Inject_Fire : BOOL;
    VO_Inject_SafeStop : BOOL;
    VO_Inject_SecurityArmed : BOOL;
    VO_Request_AwayToParty : BOOL;
    VO_Inject_Watchdog : BOOL;
END_VAR

VAR
    L_Last_Step_Time : UDINT;
END_VAR

IF NOT VI_Enable THEN
    VO_Test_Step := 0;
    VO_Status_Msg := 'Dry run disabled';
    VO_Inject_Flood := FALSE;
    VO_Inject_Gas := FALSE;
    VO_Inject_Fire := FALSE;
    VO_Inject_SafeStop := FALSE;
    VO_Inject_SecurityArmed := FALSE;
    VO_Request_AwayToParty := FALSE;
    VO_Inject_Watchdog := FALSE;
    RETURN;
END_IF;

// reset one-shot style outputs before step dispatch
VO_Inject_Flood := FALSE;
VO_Inject_Gas := FALSE;
VO_Inject_Fire := FALSE;
VO_Inject_SafeStop := FALSE;
VO_Inject_SecurityArmed := FALSE;
VO_Request_AwayToParty := FALSE;
VO_Inject_Watchdog := FALSE;

IF (VI_System_Time_MS - L_Last_Step_Time) < 5000 THEN
    RETURN;
END_IF;

L_Last_Step_Time := VI_System_Time_MS;
VO_Test_Step := VO_Test_Step + 1;

CASE VO_Test_Step OF
    1:
        VO_Inject_Flood := TRUE;
        VO_Status_Msg := 'Dry run: flood case';
    2:
        VO_Inject_Gas := TRUE;
        VO_Status_Msg := 'Dry run: gas case';
    3:
        VO_Inject_Fire := TRUE;
        VO_Status_Msg := 'Dry run: fire case';
    4:
        VO_Inject_SafeStop := TRUE;
        VO_Status_Msg := 'Dry run: safe-stop clamp';
    5:
        VO_Inject_SecurityArmed := TRUE;
        VO_Status_Msg := 'Dry run: policy away';
    6:
        VO_Request_AwayToParty := TRUE;
        VO_Status_Msg := 'Dry run: scenario guard deny';
    7:
        VO_Inject_Watchdog := TRUE;
        VO_Status_Msg := 'Dry run: watchdog case';
    ELSE
        VO_Test_Step := 0;
        VO_Status_Msg := 'Dry run: cycle restart';
END_CASE;

// >>> BULK_SYNC_ANCHOR: FB_DryRun_Simulation_Harness <<<
"""

target.write_text(content, encoding="utf-8")
print("OK: created FB_DryRun_Simulation_Harness.st")
