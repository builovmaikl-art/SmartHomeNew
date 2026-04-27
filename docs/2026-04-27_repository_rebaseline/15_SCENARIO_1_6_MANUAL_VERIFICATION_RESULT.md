# 15 - Scenario 1-6 Manual Verification Result

Date: 2026-04-27
Purpose: record manual CODESYS online verification of scenario tests 1-6.

## Mode

Manual CODESYS online observation using:

```text
GVL_TEST_PANEL
PRG_Scenario_Test_Harness
```

This is not hardware validation and not terminal build verification.

## Run mode

```text
G_Enable = TRUE
G_Scenario_Run = TRUE
G_Scenario_ID = 1..6
```

Scenarios were switched while `G_Scenario_Run` stayed TRUE.

## Results

### TEST 1 - Single circuit priority

Observed:

```text
G_Test_Result_Line = TEST 1 | Single circuit | PASS
Base = 3
Expected = 6
Actual = 6
Delta = 3
```

Result:

```text
PASS
```

### TEST 2 - Multi-zone aggregation

Observed:

```text
G_Test_Result_Line = TEST 2 | Multi-zone aggregation | PASS
```

Result:

```text
PASS
```

### TEST 3 - Preheat influence

Observed:

```text
G_Test_Result_Line = TEST 3 | Preheat influence | PASS
Delta = 2
```

Result:

```text
PASS
```

### TEST 4 - Budget vs priority

Observed:

```text
G_Test_Result_Line = TEST 4 | Budget vs priority | PASS
G_Result_Budget_Exceeded = FALSE
G_Result_Status_Msg = OK
```

Result:

```text
PASS
```

### TEST 5 - Coordinator override

Observed:

```text
G_Test_Result_Line = TEST 5 | Coordinator override | PASS
G_Input_Block_Heating = TRUE
```

Result:

```text
PASS
```

### TEST 6 - Safety dominance

Observed:

```text
G_Test_Result_Line = TEST 6 | Safety dominance | PASS
G_Input_Safety_Stop = TRUE
```

Result:

```text
PASS
```

## Overall result

```text
SCENARIO 1-6 FUNCTIONAL MANUAL VERIFICATION PASSED
```

## Known limitations

```text
manual online observation only
not hardware validation
not terminal-generated log
additional edge cases still needed
```

## Next extension

```text
TEST 7 - Combined conflict scenario
```

Purpose:

```text
Check behavior when preheat, priority, budget limit, coordinator block, and safety stop style inputs are combined.
```
