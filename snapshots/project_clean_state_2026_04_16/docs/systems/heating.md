# Heating

## Role
Heating is a policy-driven subsystem. It consumes `System Mode` from `FB_State_Manager` and publishes degradation signals upward through the diagnostics layer.

## Architecture Position
Subsystem faults -> `FB_System_Health` -> `FB_State_Manager` -> `System Mode` -> Heating policy behavior.

## Behavioral Rules
- `NORMAL`: standard weather-compensated control.
- `DEGRADED`: conservative limitation of operation.
- `FREEZE_PROTECTION`: anti-freeze behavior has priority over comfort.
- `SAFE_STOP`: active heating outputs are disabled by safety logic.

## Diagnostics Contract
- Heating does not arbitrate global mode locally.
- Heating publishes IO / sensor / subsystem degradation upward.
- Root cause and latch are handled outside Heating by the health layer.
