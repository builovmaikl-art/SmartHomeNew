# PRG_System Extraction Strategy and Architecture Debt Log

Date: 2026-04-30 (updated Phase 6)
Mode: Direct Repository Modification Mode
Scope: Phase 5–6 completed

## Decision (Finalized)

PRG_System decomposition has been executed and system switched to modular execution via MAIN.

Previous rule ("do not connect extracted blocks") is now CLOSED.

System now operates with separated PRG blocks connected in MAIN in defined order.

## Hard Editing Rule (STILL VALID)

PRG_System.st must never be partially edited.

Only full-file replacement is allowed.

This rule remains critical.

## Current System State (Actual)

### Connected execution pipeline (MAIN)

Execution order is now:

1. Time / IO / Safety
2. Intent publication
3. Health calculation
4. Alarm + Gateway intent
5. Scenario rules + arbitration
6. Access / BlackBox / History
7. Legacy PRG_System (reduced ownership)
8. Domain managers (Heating / Lighting / etc.)

### Key architectural facts

- Gateway intent is published into GVL_INTENT_USER
- Scenario rules consume GVL_INTENT_USER (not GVL_COMMAND)
- Execution order guarantees data freshness in same cycle
- Modbus map aligned with 16 heating circuits (per specification)

## CLOSED Debts

### DEBT-001 — Health extraction

Status: CLOSED

- PRG_System_Health connected in MAIN
- GVL_SYSTEM_HEALTH is single source of truth

### DEBT-002 — Multi-contour ownership

Status: PARTIALLY CLOSED

- Most contours extracted and connected
- PRG_System still exists as legacy container

### DEBT-003 — Time duplication

Status: OPEN (low priority)

- PRG_System may still contain legacy time calls

### DEBT-004 — Intent duplication

Status: OPEN (cleanup)

- Legacy declarations may remain in PRG_System

### DEBT-005 — Duplicate execution risk

Status: CLOSED

- MAIN orchestrates execution order
- No duplicate contour execution detected

## NEW Debts (Phase 6)

### DEBT-006 — Documentation drift

Status: RESOLVED

Documentation aligned with code.

### DEBT-007 — PRG_System still present

Status: ACTIVE (Phase 7)

PRG_System still executes alongside modular blocks.

## Final Architecture Direction

System has transitioned from monolith → orchestrated modular pipeline.

Next phase is:

- removing PRG_System ownership completely
- leaving it as thin compatibility shell or removing entirely

## Verification Checklist (Updated)

System is considered stable if:

- No ARRAY mismatches
- No Modbus overlaps
- Scenario pipeline works in one cycle
- Gateway → Intent → Scenario chain is consistent
- Health → Alarm → History chain is consistent

