# AGENTS.md — SmartHomeNew current repository instructions

## 0. Current repository status

This repository is now an adaptive, command-aware PLC control architecture.

The current runtime pipeline is:

```text
PRG_Time_Service
→ PRG_IO_Read
→ PRG_Input_Processing
→ PRG_User_Adapt_Control
→ PRG_Behavior_Adapt_Profile
→ PRG_Safety
→ PRG_Safety_Shutdown
→ PRG_Safety_Recovery
→ system/support PRGs
→ PRG_Scenario_Engine
→ PRG_Command_Arbitration
→ PRG_Command_Verifier
→ domain PRGs
→ PRG_Explainability
→ PRG_Debug_View
→ PRG_IO_Write
```

Core runtime architecture:

```text
IO → INPUT → SCENARIO/SAFETY → COMMAND → DOMAIN OUTPUT → IO
                         ↓
          TRACE / EXPLAINABILITY / DEBUG_VIEW / ADAPT
```

The source of truth is always the actual repository code, not older audit documents or chat history.

---

## 1. Mandatory first step

Before doing any analysis, planning, coding, or proposing changes for this repository, read:

1. `AGENTS.md`
2. newest relevant audit/report files under `docs/`
3. newest files under `документация проекта/` if present

If there is a conflict:

```text
actual repository code > current AGENTS.md > MASTER_GUIDE / WORKFLOW > architecture docs > old audit docs > chat memory
```

Never rely on assumed repository state.

---

## 2. Current control ownership model

### 2.1 Input ownership

```text
PRG_IO_Read owns raw acquisition / calibration into GVL_STATE.
PRG_Input_Processing owns normalized read-model publication into GVL_INPUT.
Scenario / diagnostics / adaptive logic should prefer GVL_INPUT over GVL_STATE.
```

`GVL_STATE` may still exist for legacy/domain internals, but new high-level logic must not bypass `GVL_INPUT` without documenting why.

### 2.2 Scenario ownership

```text
PRG_Scenario_Engine owns behavior intent:
- scenario scores
- request flags
- multi-objective weights
- best VentBoost zone
- behavior reason text
```

Scenario must not write physical IO, command shadow, or domain output GVLs.

### 2.3 Safety ownership

```text
PRG_Safety owns hazard detection and projection into GVL_INTENT_SAFETY.
PRG_Safety_Shutdown owns global safety mode selection.
PRG_Safety_Recovery owns recovery phase control.
```

Safety has priority over comfort, behavior, user requests, adaptation, and domain control.

### 2.4 Command ownership

```text
PRG_Command_Arbitration owns GVL_COMMAND_SHADOW.
```

It must:

```text
1. fully reset command shadow every cycle
2. project safety mode and safety intent into commands
3. pass allowed user intents only through the safe path
4. apply recovery clamps
5. eliminate contradictory command pairs
```

No domain PRG may independently reinterpret high-level safety intent when a command shadow field already exists for that purpose.

### 2.5 Domain ownership

Domain PRGs own domain execution only:

```text
PRG_Heating      → GVL_HEATING_OUTPUT
PRG_Ventilation  → GVL_VENT_OUTPUT
PRG_Water        → GVL_WATER_OUTPUT
PRG_Access       → GVL_ACCESS_OUTPUT
```

Domain PRGs must not write physical `GVL_IO` directly.

### 2.6 IO ownership

```text
PRG_IO_Write is the only final physical output projection layer.
```

It must map domain output GVLs and command clamps into `GVL_IO`.

Final IO safety clamps belong here only as last-line output clamping, not as a second command system.

### 2.7 Trace / explainability / debug ownership

```text
GVL_TRACE + FB_Trace_Write = event history / blackbox.
GVL_EXPLAINABILITY + PRG_Explainability = current reason chain.
GVL_DEBUG_VIEW + PRG_Debug_View = read-only engineering snapshot.
```

Debug and explainability must not control the system.

---

## 3. Current adaptive behavior model

The adaptive subsystem is profile-controlled:

```text
ADAPT_PROFILE_STABLE
ADAPT_PROFILE_BALANCED
ADAPT_PROFILE_AGGRESSIVE
```

`PRG_Behavior_Adapt_Profile` centrally applies:

```text
G_Adapt_Learning_Rate
G_Confidence_Learning_Rate
G_Decay_Factor
G_Adapt_Update_Threshold
```

HMI/profile switching must go through:

```text
GVL_INTENT_USER → PRG_User_Adapt_Control → GVL_BEHAVIOR_ADAPT.G_Adapt_Profile
```

Rules:

```text
- profile changes require explicit confirm
- profile changes require sufficient access level
- profile changes are blocked during safety/recovery
- accepted and rejected profile changes must be traceable
```

Adaptive feedback must use real baseline memory, not hard-coded baseline constants.

---

## 4. HMI / dashboard rule

HMI/Web dashboard must be read-only by default.

Primary source:

```text
GVL_DEBUG_VIEW
```

Allowed control path:

```text
HMI → GVL_INTENT_USER → command/safety pipeline → domain → IO
```

Forbidden:

```text
HMI → GVL_IO
HMI → GVL_COMMAND_SHADOW
HMI → domain output GVLs
HMI → adaptive weights directly
```

---

## 5. File integrity rule — mandatory

After any repository modification:

```text
1. Immediately re-read the modified file from the repository.
2. Verify that the full structure is present.
3. Verify no truncated logic blocks.
4. Verify no missing CASE branches / function blocks / declarations.
5. Verify no accidental overwrite of unrelated logic.
6. Only then proceed to the next change.
```

Strictly forbidden:

```text
- multiple sequential runtime modifications without intermediate verification
- assuming logic remains unchanged
- continuing after a failed or partial update without checking repository state
```

User-specific operational rule:

```text
When changing an existing code file through repository tools, rewrite the complete file content with the required edits and then verify by fetching it back.
Do not paste partial snippets into existing files as the primary edit method.
```

---

## 6. Editing discipline

### Preferred for runtime files

For runtime-affecting files:

```text
fetch full file → prepare complete replacement → update file → fetch again → verify
```

This is mandatory when using direct repository tools and the user explicitly requests full-file rewrites.

### Anchor-based edits

If deterministic anchor blocks already exist, preserve them.

Anchor rule:

```text
// === BEGIN BLOCK_NAME ===
...
// === END BLOCK_NAME ===
```

Do not rely on ambiguous single-line matches like `END_IF` or `END_CASE`.

### Repair scripts

When terminal/full repository execution is available, non-trivial changes should be materialized as deterministic repair scripts under `steps/`.

When only Direct Repository Modification Mode is available, direct updates are allowed but must be explicitly identified as file-state verification, not terminal/build verification.

---

## 7. Verification modes

### 7.1 Full Verification Mode

Preferred mode when terminal/build tools are available.

Confirmed only after:

```text
1. repair/change execution
2. git diff inspection
3. build/compile or execution logs when applicable
4. scenario/test validation if relevant
```

### 7.2 Analytical Verification Mode

Allowed when execution is unavailable.

Can include:

```text
- reading repository files
- checking symbol consistency
- checking control/data flow
- checking missing fields/enums
```

Must not claim runtime/build success.

### 7.3 Direct Repository Modification Mode

Allowed when repository tools can mutate files.

Rules:

```text
- fetch before update
- update complete file
- fetch after update
- state clearly that verification is repository file-state verification
- do not fabricate terminal/build output
```

Runtime-affecting changes still need real build/PLC validation later.

---

## 8. Mandatory post-change checks

After runtime-affecting changes, check at minimum:

```text
- referenced enum values exist
- referenced GVL fields exist
- arrays use declared bounds
- command shadow reset covers all fields
- domain output GVLs are consumed by PRG_IO_Write
- scenario/explainability/debug do not control outputs
- safety cannot be bypassed by user/HMI/profile changes
```

For recent architecture, explicitly check:

```text
GVL_INPUT field names use IN_* prefix.
PRG_Scenario_Engine must not use non-existent I_* input names.
I_Selected_Scenario_Text must not be a stub.
Reason chain must not be empty.
PRG_IO_Write must consume Heating/Vent/Water/Access output GVLs.
```

---

## 9. Documentation discipline

Documentation updates must reflect current repository state.

Rules:

```text
- do not let old audit documents override current code
- final/system documents should be copied or maintained under `документация проекта/` when requested
- temporary audit documents may remain under `docs/`
- obsolete documents should be removed only when they are clearly superseded and the user requested cleanup
```

When creating audit reports, mark whether they are:

```text
- code-first static audit
- repository file-state verification
- terminal/build verification
- runtime/PLC verification
```

---

## 10. Safety cleanup priority from current instruction state

The latest safety ownership segmentation identifies four clusters:

```text
1. core hazard / interlock projection
2. operator / test / recover workflow
3. safety-access coupling
4. producer-heavy publication tail
```

Current best minimal cleanup target:

```text
Cluster 2 — operator / test / recover workflow
```

Any future safety refactor should begin by separating operator/test/recover workflow from hazard detection/projection, unless a higher-priority compile/runtime fault exists.

---

## 11. Forbidden patterns

```text
- direct HMI writes to IO/command/domain outputs
- scenario writing command shadow or IO
- domain writing physical IO directly
- debug/explainability writing control signals
- safety bypass through user intent
- hidden partial file modifications
- claiming build success without build evidence
- using chat memory as repository truth
- adding new runtime layers without connecting them into MAIN
- creating duplicate blackbox/debug logs instead of views over existing trace/debug state
```

---

## 12. New chat bootstrap prompt

Recommended opening instruction for any new assistant session:

```text
Read AGENTS.md Work only from the current repository state. Preserve the active pipeline IO → INPUT → SCENARIO/SAFETY → COMMAND → DOMAIN OUTPUT → IO, with TRACE/EXPLAINABILITY/DEBUG_VIEW as read-only observability. Use full-file repository updates with fetch-after verification for existing code files. Do not claim terminal/build verification unless it was actually run. For safety refactors, prioritize separating operator/test/recover workflow from PRG_Safety after any compile/runtime blockers are resolved.
```
