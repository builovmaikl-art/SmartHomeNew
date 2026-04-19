# Calibration — Phase 3 (Generic families baseline)

## Status
OK: compiled, integrated

## Covered families
- Gas family:
  - CO
  - Methane
- Temperature family:
  - FloorTemp1
  - FloorTemp2
  - OutdoorTemp

## Architecture
- Raw acquisition remains per-sensor where needed
- Calibration / verification / write-back / telemetry are grouped by family
- Backward-compatible aliases preserved for existing scalar variables

## Current model
- Gas family uses generic loop over processed channels
- Temperature family uses generic loop over raw channels
- verification_passed write-back preserved
- telemetry counters/history preserved

## Next
- mapping table instead of fixed index offsets
- optional HMI/export polish
- threshold tuning
