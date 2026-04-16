FUNCTION_BLOCK FB_DryRun_Assertion_Map
VAR_INPUT
    VI_Test_Step : INT;
END_VAR

VAR_OUTPUT
    VO_Expected_Result : STRING(220);
END_VAR

CASE VI_Test_Step OF
    1:
        VO_Expected_Result := 'EXPECT: Flood alarm active, leak safety path active, water confirm blocked';
    2:
        VO_Expected_Result := 'EXPECT: Gas alarm active, gas valve close path, gas safety latched';
    3:
        VO_Expected_Result := 'EXPECT: Fire alarm active, smoke safety path, safe-stop tendency';
    4:
        VO_Expected_Result := 'EXPECT: Scenario NONE clamp under SAFE_STOP/FREEZE rules';
    5:
        VO_Expected_Result := 'EXPECT: Scenario forced to AWAY by security policy';
    6:
        VO_Expected_Result := 'EXPECT: Guard denies AWAY->PARTY, scenario remains unchanged';
    7:
        VO_Expected_Result := 'EXPECT: Watchdog root cause and event 11/12 path';
    ELSE
        VO_Expected_Result := 'EXPECT: No active dry-run case';
END_CASE;

// >>> BULK_SYNC_ANCHOR: FB_DryRun_Assertion_Map <<<
