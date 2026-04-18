# Heating Protection — Phase 1 (Observer baseline)

## Status
OK: integrated, compiled

## Components
- FB_FloorHeating_Freeze_Protection
- FB_FloorHeating_Overheat_Protection
- PRG_System observer layer

## Signals (Diagnostics)
- Heating_Freeze_Alert
- Heating_Freeze_Pump_Force_Request
- Heating_Overheat_Detected
- Heating_Overheat_Locked_Circuits[]
- Heating_Protection_Summary_Text

## Behavior
- no control override
- no actuator forcing
- diagnostics only

## Next
- enforcement layer (pump / valves)
- safety policy (priority, overrides)
