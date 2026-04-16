# DHW

## Role
DHW consumes `System Mode`, applies policy restrictions, and exports diagnostics upward.

## Behavioral Rules
- `NORMAL`: standard DHW heating and recirculation.
- `DEGRADED`: conservative limitation, including reduced target temperature when configured.
- `FREEZE_PROTECTION`: pumps are stopped in the current architecture.
- `SAFE_STOP`: DHW pumps are stopped.

## Diagnostics Contract
- IO faults must be surfaced upward.
- Sensor faults must be surfaced upward.
- DHW does not decide global system mode on its own.
