# Snapshot Layer — Phase 2 (Multi-event baseline)

## Status
OK: stable, compiled

## Triggers
- rate alert (edge)
- fallback spike
- recovery spike

## Behavior
- one snapshot per trigger
- no debounce
- no persistence

## Components
- FB_State_Snapshot_Manager
- PRG_System integration

## Next
- debounce / hysteresis
- persistence layer (NVRAM/file)
