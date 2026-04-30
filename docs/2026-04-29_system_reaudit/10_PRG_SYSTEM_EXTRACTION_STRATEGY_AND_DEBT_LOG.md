# PRG_System Extraction Strategy and Architecture Debt Log

Date: 2026-04-30
Mode: Direct Repository Modification Mode
Scope: Phase 5 — PRG_System decomposition

## Decision

Do not continue by cutting PRG_System first.

The active strategy is:

1. Extract all visible PRG_System-owned blocks into separate PRG/FB units.
2. Keep PRG_System behavior intact while extracted blocks are being prepared.
3. Do not connect extracted blocks if PRG_System still executes the same ownership contour.
4. After all blocks are extracted and verified, reduce PRG_System in one controlled full-file replacement.
5. Connect the extracted blocks in MAIN in the correct execution order.
6. Verify insertion integrity and ownership uniqueness after every full-file replacement.

## Hard Editing Rule

PRG_System.st must never be partially edited.

Allowed operation:

- fetch current complete file
- prepare complete replacement file
- update_file with full content only
- fetch again
- verify file is complete and not truncated

Forbidden operation:

- partial insertion
- partial deletion
- hand-built shortened replacement
- replacing PRG_System with a reduced sketch

This rule exists because PRG_System was already damaged twice by incomplete full-file replacements during Phase 5 attempts.

## Current Known State

### Already extracted / existing

- PRG_System_Intent.st exists and is connected in MAIN.
- PRG_System.st no longer calls fbSystemIntentPublisher directly.
- PRG_System_Health.st exists.
- GVL_SYSTEM_HEALTH.gvl exists as a prepared global health snapshot.
- PRG_System_Health.st currently routes FB_System_Health_Orchestrator outputs into GVL_SYSTEM_HEALTH.

### Currently not connected

- PRG_System_Health is intentionally not connected in MAIN at this point.
- PRG_System still owns and executes the live health contour via fbSystemHealthOrchestrator.

## Architecture Debts

### DEBT-001 — Health extraction prepared but not switched

PRG_System_Health and GVL_SYSTEM_HEALTH are prepared, but PRG_System still executes fbSystemHealthOrchestrator.

Reason:

- Consumers inside PRG_System still depend on local health values.
- Switching requires coordinated consumer migration.
- Cutting PRG_System before all extraction work is complete is no longer the selected strategy.

Status: documented / deferred.

### DEBT-002 — PRG_System still owns multiple contours

PRG_System still owns or orchestrates:

- init / recovery
- time legacy calls
- persist manager
- redundancy
- health
- evacuation
- astro timer
- scenario arbitration
- simulation
- rule engine
- alarm orchestration
- gateway intent
- blackbox
- history
- dangerous action confirmation
- maintenance access enforcement
- NVRAM snapshot mirroring
- event logging

Status: active Phase 5 decomposition target.

### DEBT-003 — Time service duplication remains inside PRG_System

PRG_Time_Service exists and runs from MAIN, but PRG_System still calls fbTimebase/fbTime locally.

Status: extraction candidate.

### DEBT-004 — Intent extraction complete but legacy declaration remains

PRG_System no longer calls fbSystemIntentPublisher, but the local fbSystemIntentPublisher declaration remains.

Status: harmless cleanup tail.

### DEBT-005 — Extracted blocks must not be connected prematurely

Several blocks may exist before switching ownership. Connecting them while PRG_System still owns the same contour can cause duplicate writes to GVL_STATE/GVL_STATUS/GVL_GATEWAY.

Status: active safety rule.

## Proposed Extraction Order

The preferred extraction order is based on risk and dependency direction:

1. Documentation map of all PRG_System contours.
2. Pure or mostly isolated publication blocks.
3. Gateway intent / scenario request adapters.
4. History and blackbox reporting blocks.
5. Alarm orchestration wrapper.
6. Persistence / recovery wrappers.
7. Health switch only after consumers are fully mapped.
8. Final PRG_System cleanup as a single full-file replacement.

## Verification Checklist For Each Extraction

For every extracted block:

- Source contour identified in PRG_System.
- Inputs listed.
- Outputs listed.
- GVL writes listed.
- Duplicate execution risk assessed.
- MAIN connection order defined.
- PRG_System removal deferred until final cleanup unless the block has no remaining consumers.
- Full-file replacement verified after write.
- File end marker / END_PROGRAM present.

## Current Next Step

Create a detailed PRG_System decomposition map before further code changes.

Recommended next document:

- docs/2026-04-29_system_reaudit/11_PRG_SYSTEM_DECOMPOSITION_MAP.md

