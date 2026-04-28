PROGRAM PRG_Test_Injection

// Non-intrusive test injection layer
// Must be called AFTER PRG_IO_Read and BEFORE PRG_Safety

IF NOT GVL_TEST_INJECTION.G_Inject_Enable THEN
    RETURN;
END_IF;

// ===== GAS INJECTION =====
IF GVL_TEST_INJECTION.G_Inject_Gas_Level > 0.0 THEN
    GVL_STATE.G_Methane_Sensors[1] := GVL_TEST_INJECTION.G_Inject_Gas_Level;
END_IF;

// ===== IO OFFLINE INJECTION =====
IF GVL_TEST_INJECTION.G_Inject_Force_IO_Offline THEN
    GVL_STATUS.G_IO_Modules_Online[1] := FALSE;
    GVL_STATUS.G_IO_Modules_Online[2] := FALSE;
END_IF;

// ===== OWNERSHIP VIOLATION TEST =====
// Intentionally break safety to verify watchdog
IF GVL_TEST_INJECTION.G_Inject_Force_Gas_Alarm_Reset THEN
    GVL_STATE.G_Safety_Gas_Alarm := FALSE;
END_IF;
