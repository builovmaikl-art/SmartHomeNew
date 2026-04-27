# AGENTS.md — SmartHomeNew entry instructions

## Mandatory first step
Before doing any analysis, planning, coding, or proposing changes for this repository, read:

1. `docs/MASTER_GUIDE.md`
2. `docs/WORKFLOW.md`
3. `docs/CHANGELOG_WORK.md`
4. `docs/ARCHITECTURE_NOTES.md`
5. `docs/EQUIPMENT_DECISIONS.md`
6. `docs/IO_MAPPING_CONCEPT.md`

## Additional Engineering Principle (Test Panel)

The repository uses an internal scenario test panel approach for logic verification:

```text
GVL_TEST_PANEL + PRG_Scenario_Test_Harness
```

Rules:

- All new logic must be verifiable via scenario-based tests when possible
- Scenario tests must:
  - allow manual input changes
  - expose expected vs actual values
  - provide clear pass/fail state
- Prefer "single screen" verification (no multi-window inspection)
- Scenario tests act as pre-hardware commissioning layer
- They must NOT write into:
  - GVL_STATE
  - GVL_IO
  - actuator outputs

Purpose:

```text
reduce manual inspection
reduce integration risk
allow fast behavioral validation before hardware is available
```

## Working rules
- Treat this repository as an engineering system, not a collection of isolated features.
- Safety has priority over comfort, but false escalation must be avoided.
- Do not blindly replay old step scripts as the main integration mechanism.
- New work should be integrated against the current repository state.
- Accepted decisions must be reflected in the relevant docs before or together with code changes.
- Preserve fail-safe behavior.

## Repository execution discipline
- Work is performed against the current observable repository state only.
- The source of truth is:
  - repository files
  - current `git diff`
  - execution logs and errors

## Mandatory Post-Change Verification Rule

After any change:

```text
1. verify repository state
2. ensure no unintended changes
3. validate via scenario test panel when applicable
```

(remaining content unchanged)
