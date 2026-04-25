PROGRAM PRG_Test_Scenario_Runner

IF NOT GVL_TEST.G_Test_Enable THEN
    RETURN;
END_IF;

CASE GVL_TEST_INJECTION.G_Test_Step OF

0:
    // idle
    
1:
    // simulate gas spike
    GVL_TEST_INJECTION.G_Inject_Gas_Level := 50.0;
    GVL_TEST_INJECTION.G_Test_Step := 2;

2:
    // simulate illegal reset
    GVL_TEST_INJECTION.G_Inject_Force_Gas_Alarm_Reset := TRUE;
    GVL_TEST_INJECTION.G_Test_Step := 3;

3:
    // simulate IO offline
    GVL_TEST_INJECTION.G_Inject_Force_IO_Offline := TRUE;
    GVL_TEST_INJECTION.G_Test_Step := 4;

4:
    // stop
    GVL_TEST_INJECTION.G_Inject_Enable := FALSE;

END_CASE;
