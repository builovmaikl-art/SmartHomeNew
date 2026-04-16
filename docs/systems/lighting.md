# Lighting and Blinds

## Role
Lighting and blinds consume `System Mode` and remain subordinate to Policy.

## Behavioral Rules
- `NORMAL`: scenarios and normal automation allowed.
- `DEGRADED`: simulation-driven behavior is disabled.
- `FREEZE_PROTECTION`: scenario-driven behavior is restricted.
- `SAFE_STOP`: lights off, blinds open, unless dedicated emergency behavior is defined elsewhere.

## Diagnostics Contract
- Lighting publishes relevant IO degradation upward.
- Lighting does not decide system mode.
