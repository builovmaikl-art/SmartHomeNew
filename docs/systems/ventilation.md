# Ventilation

## Role
Ventilation is subordinate to Policy and consumes `System Mode`.

## Behavioral Rules
- `NORMAL`: scenario-based operation.
- `DEGRADED`: limited operation instead of full shutdown where allowed by design.
- `FREEZE_PROTECTION`: current architecture keeps ventilation stopped.
- `SAFE_STOP`: ventilation and heater outputs are stopped.

## Diagnostics Contract
- Ventilation publishes IO and degraded state upward.
- Ventilation does not arbitrate global mode locally.
