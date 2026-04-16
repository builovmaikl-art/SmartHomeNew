# Verification remediation plan

## Context
- This plan addresses gaps identified in `full_verification_report_2026-03-24.md`.
- Goal: convert static/document-level confidence into implementation-level and import-level confidence.

## Gap 1 — no native CODESYS compile/import validation
### Risk
- Static checks can miss semantic/type/device-tree errors.

### Actions
1. Run a real CODESYS 3.5 SP17 compile on target device profile.
2. Perform import test from selected package format (`.projectarchive` preferred).
3. Export symbol configuration and verify external interfaces (HMI/SCADA/gateway).

### Acceptance criteria
- Zero compile errors.
- Zero unresolved libraries/devices.
- Import/restore roundtrip succeeds without object loss.

## Gap 2 — target IO architecture is not yet reflected in runtime aggregate
### Risk
- `result.txt` still contains legacy physical channels that conflict with the bus-centric target architecture.

### Actions
1. Create explicit migration branch for bus-centric model:
   - boiler I/O removal in favor of OpenTherm data model,
   - room climate/switches moved from physical DI/AI to fieldbus inputs,
   - flood/valve/siren/socket reductions applied to constants and IO structures.
2. Add compatibility layer for gradual rollout:
   - temporary dual-source inputs (`physical OR fieldbus`) with feature flags.
3. Update all dependent loops/bounds/maps after constant changes.

### Acceptance criteria
- No references to removed channels remain in PRG_IO_Read/Write and managers.
- All `C_MAX_*` and IO arrays are internally consistent.
- Target channel counts match `io_reviewed_target_spec.md`.

## Gap 3 — watchdog coverage remains partial
### Risk
- Module health is supervised only for first modules; silent failures possible on remaining modules.

### Actions
1. Replace fixed watchdog instances with scalable array-based watchdog manager.
2. Cover full installed module count from configuration.
3. Add alarm/logging on module status transitions.

### Acceptance criteria
- Every configured module has heartbeat supervision.
- Alarm is raised on timeout and auto-clears on recovery.

## Gap 4 — verification is mostly text-pattern based
### Risk
- False sense of confidence if checks do not validate semantics.

### Actions
1. Add machine-verifiable checks:
   - IO budget checker script from source-of-truth tables,
   - consistency checker for constants vs array sizes vs loops.
2. Add deterministic simulation scenarios:
   - fire/flood/security,
   - OpenTherm communication loss,
   - fieldbus sensor timeout/fallback behavior.

### Acceptance criteria
- Repeatable verification scripts pass in CI-like environment.
- Scenario traces are archived with pass/fail markers.

## Recommended implementation order
1. CODESYS import/compile validation baseline.
2. IO model migration and constant/array alignment.
3. Watchdog scaling and diagnostics.
4. Automated semantic verification and simulation scenarios.
