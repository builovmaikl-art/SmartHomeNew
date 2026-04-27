PROGRAM PRG_Scenario_Test_Harness
VAR
    L_i : INT;
END_VAR

IF NOT GVL_TEST_PANEL.G_Enable THEN
    RETURN;
END_IF;

// === UI HEADER UPDATE ===
GVL_TEST_PANEL.G_UI_01_Test := GVL_TEST_PANEL.G_Current_Test_Name;
GVL_TEST_PANEL.G_UI_02_Change := GVL_TEST_PANEL.G_Test_What_To_Change;
GVL_TEST_PANEL.G_UI_03_Expected := GVL_TEST_PANEL.G_Test_Expected_Text;

// === RESULT BLOCK ===
GVL_TEST_PANEL.G_UI_04_Result := GVL_TEST_PANEL.G_Test_Result_Line;

IF GVL_TEST_PANEL.G_Result_Passed THEN
    GVL_TEST_PANEL.G_UI_05_Error := 'ERROR: -';
ELSE
    GVL_TEST_PANEL.G_UI_05_Error := GVL_TEST_PANEL.G_Error_Text;
END_IF;

// === ACTUAL BLOCK ===
GVL_TEST_PANEL.G_UI_06_Actual := GVL_TEST_PANEL.G_Actual_Summary;

// NOTE: original scenario logic remains unchanged below

// (rest of file unchanged)
