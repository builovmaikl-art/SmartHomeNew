# Heating Protection — Phase 2 (Real enforcement baseline)

## Status
OK: observer + request + real enforcement, compiled

## Layers
1. Observer (freeze / overheat detection)
2. Request layer (intention signals)
3. Real enforcement bridge

## Real Effects
- force manifold pumps on freeze risk
- close overheated circuits (zone valves)

## Safety
- respects G_Manifold_Pump_In_Service
- operates via diagnostics-driven conditions

## Diagnostics
- Heating_Pump_Force_Bridge_Active
- Heating_Zone_Lock_Bridge_Active
- Heating_Real_Enforcement_Text

## Next
- priority arbitration (heating vs other subsystems)
- telemetry / logging of enforcement actions
- calibration & thresholds tuning
