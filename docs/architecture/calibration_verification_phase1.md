# Calibration Verification — Phase 1 (Observer baseline)

## Status
OK: integrated, compiled

## Components
- FB_Calibration_Manager (verification)
- FB_Sensor_Calibration_Processor (unchanged main calibration)
- PRG_System verification observer layer

## Behavior
- verification starts on calibration timestamp change
- 1h verification window (per FB logic)
- deviation calculated in percent
- failure if deviation > 5%

## Signals (Diagnostics)
- Calibration_CO_Verification_Active
- Calibration_CO_Verification_Failed
- Calibration_CO_Deviation_Percent
- Calibration_Methane_Verification_Active
- Calibration_Methane_Verification_Failed
- Calibration_Methane_Deviation_Percent
- Calibration_Verification_Summary_Text

## Architecture
- non-invasive: does not alter main calibration path
- observer-only integration

## Next
- write-back to calibration record (verification_passed)
- verification telemetry / history
- threshold tuning (2% / 5%)
