# Restore PRG_Safety full body

## Strategy
Reconstruct `PRG_Safety.st` using:
1. full body from `snapshots/project_clean_state_2026_04_16/PRG_Safety.st`
2. preserve newer current-intent changes where they are clearly intentional:
   - command edge processing vars and logic
   - `GVL_Safety_Selector.*_Effective_Array` inputs for gas/smoke manager
   - single-owner system mode comment (no mode arbitration in safety)

## Goal
Produce a complete, non-truncated `PRG_Safety.st` as the base for subsequent migration to `GVL_INTENT_SAFETY`.
