# 17 - Audit Current Checkpoint

Date: 2026-04-27

Purpose: зафиксировать не только состояние test harness, но и общую точку аудита проекта: что уже проверено, что стабилизировано, что требует дальнейшего устранения перед реальным внедрением.

---

## Current audit phase

```text
PHASE: repository rebaseline / verification-first stabilization
PROJECT STATE: доведение до реального внедрения, не начальная разработка
CURRENT FOCUS: audit findings + safe correction workflow + scenario verification layer
```

Ключевая установка:

```text
Все найденные недостатки фиксируются для последующего устранения.
Проект рассматривается как инженерная система, а не набор независимых фич.
```

---

## Current source of truth

```text
1. repository files
2. current CODESYS compilation result
3. manual online observations from user
4. documents in docs/2026-04-27_repository_rebaseline
5. AGENTS.md workflow rules
```

Не считать источником истины:

```text
chat memory without repository confirmation
assumptions about file state
partial patch snippets
```

---

## Main process decision reached

### Mandatory file integrity rule

После любой правки:

```text
1. immediately re-read modified file from repository
2. verify full file structure
3. confirm no placeholders / truncation / missing logic
4. only then continue
```

Причина:

```text
During this session, partial-file updates repeatedly caused loss of full PRG logic.
This is now treated as a high-risk anti-pattern.
```

Forbidden patterns:

```text
... rest unchanged ...
ONLY PATCHED PART
rest unchanged
partial PRG replacement
assuming old logic remains present
```

---

## Major audit/stabilization work completed

### 1. Repository documentation baseline

Created / updated rebaseline documents under:

```text
docs/2026-04-27_repository_rebaseline/
```

Purpose:

```text
preserve audit findings, current decisions, test direction, and stop/resume points
```

### 2. Main instruction hardening

Updated:

```text
AGENTS.md
```

Added / reinforced:

```text
- control hierarchy
- scenario test panel principle
- mandatory file integrity rule
- direct modification transparency
- post-change verification discipline
```

### 3. Scenario harness created and evolved

Current files:

```text
PRG_Scenario_Test_Harness.st
GVL_TEST_PANEL.gvl
GVL_TEST_PANEL_RESULT.gvl
GVL_TEST_PANEL_DEBUG.gvl
```

Current architecture:

```text
GVL_TEST_PANEL_RESULT = operator/HMI window
GVL_TEST_PANEL_DEBUG  = diagnostic window
GVL_TEST_PANEL        = internal state/core panel
PRG_Scenario_Test_Harness = scenario engine
```

Current model:

```text
hold-preset
G_Scenario_Run = TRUE  -> scenario continuously holds preset inputs
G_Scenario_Run = FALSE -> scenario releases inputs to neutral defaults
```

### 4. Manual scenario verification performed

Earlier manual online verification confirmed:

```text
TEST 1-6: observed PASS
```

After later RESULT/DEBUG restructuring:

```text
TEST 1-7 must be re-run from GVL_TEST_PANEL_RESULT
```

---

## Current test harness status

Detailed state is documented in:

```text
16_SCENARIO_HARNESS_CURRENT_STATE.md
```

Current intended workflow:

```text
open GVL_TEST_PANEL_RESULT
set G_Enable = TRUE
set G_Scenario_Run = TRUE
switch G_Scenario_ID 1..7
observe G_Test_Result_Line / G_Result_Passed / G_Result_Fail_Code
open GVL_TEST_PANEL_DEBUG only if mismatch/error occurs
```

Important current caveat:

```text
The last PRG restoration must be compiled and checked in CODESYS after repository update.
```

---

## Known audit findings / unresolved items

### A. Test harness architecture still CASE-based

Current:

```text
CASE G_Scenario_ID OF
```

Risk:

```text
adding many tests will make PRG large and harder to maintain
```

Recommended future direction:

```text
ST_TestScenario + scenario array + executor
```

Status:

```text
not urgent, but should be addressed before large test expansion
```

### B. TEST 5-7 are scenario-model checks

Current:

```text
TEST 5 coordinator override
TEST 6 safety dominance
TEST 7 conflict dominance
```

Limit:

```text
these validate modeled dominance behavior, not full real hardware or all real FB paths
```

Future:

```text
connect selected scenarios to real FB paths where safe
```

### C. Hardware validation is not started

Reason:

```text
hardware is not selected / not available yet
```

Status:

```text
out of current scope
```

Current safe substitute:

```text
pre-hardware scenario harness / digital-twin-light verification
```

### D. Compilation / terminal verification

Current facts:

```text
CODESYS compilation was performed by user during the session.
Some errors were found when PRG was accidentally truncated.
After restoration, compilation status must be confirmed again.
```

Status:

```text
needs explicit re-check after latest PRG restore
```

### E. RESULT/DEBUG restructuring needs final online confirmation

Current expectation:

```text
RESULT controls G_Enable / G_Scenario_ID / G_Scenario_Run
PRG reads RESULT controls
PRG mirrors result back to RESULT and diagnostics to DEBUG
```

Needed confirmation:

```text
switch Scenario_ID in RESULT and confirm result line and key values update
```

---

## What is considered stable now

```text
- audit workflow discipline is established
- file integrity rule is documented and mandatory
- scenario verification direction is accepted
- RESULT/DEBUG split is the chosen UX architecture
- hold-preset model is the chosen run model
- TEST 1-7 are the current scenario scope
```

---

## What must not be changed casually

```text
1. safety > coordinator > budget/eligibility > priority/policy/preheat > domain hierarchy
2. RESULT/DEBUG split without documenting reason
3. file integrity rule
4. no-placeholder rule
5. pre-hardware scenario harness direction
```

---

## Recommended next checkpoint actions

### Step 1 - Compile after latest PRG restore

```text
Compile in CODESYS after latest PRG_Scenario_Test_Harness restore.
```

Record:

```text
compile OK / errors
error list if any
```

### Step 2 - Re-run TEST 1-7 from RESULT

```text
GVL_TEST_PANEL_RESULT.G_Enable := TRUE
GVL_TEST_PANEL_RESULT.G_Scenario_Run := TRUE
GVL_TEST_PANEL_RESULT.G_Scenario_ID := 1..7
```

Record:

```text
G_Test_Result_Line
G_Result_Passed
G_Result_Fail_Code
key observed values
```

### Step 3 - Update verification result document

If TEST 1-7 pass after RESULT/DEBUG restructuring, create/update:

```text
SCENARIO_1_7_RESULT_DEBUG_VERIFICATION_RESULT
```

### Step 4 - Continue audit corrections

After harness confirmation, continue with either:

```text
A. data-driven scenario architecture
B. next unresolved audit findings outside test harness
C. connect selected scenarios closer to real FB paths
```

---

## Resume point for next session

Start here:

```text
Read AGENTS.md.
Read docs/2026-04-27_repository_rebaseline/16_SCENARIO_HARNESS_CURRENT_STATE.md.
Read docs/2026-04-27_repository_rebaseline/17_AUDIT_CURRENT_CHECKPOINT.md.
Compile after latest PRG restore.
Re-run TEST 1-7 from GVL_TEST_PANEL_RESULT.
Then continue audit correction based on observed results.
```

---

## Current overall status

```text
AUDIT CHECKPOINT: active stabilization point
CONFIDENCE: medium-high for architecture direction
CONFIDENCE BLOCKER: latest PRG restore requires compile + online verification
NEXT REQUIRED EVIDENCE: CODESYS compile and TEST 1-7 RESULT-window run
```
