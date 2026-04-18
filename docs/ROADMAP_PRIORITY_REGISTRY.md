# ROADMAP PRIORITY REGISTRY

Updated: 2026-04-18

---

## Priority legend

- HIGH — next implementation candidates
- MEDIUM — useful but not urgent
- LOW — parked / library / optional
- IGNORE — do nothing (already covered or obsolete)

---

## HIGH PRIORITY (next wave)

| Object | Priority | Why |
|---|---|---|
| FB_Gas_Valve_Controller.st | HIGH | Already domain-ready, ties directly into safety outputs |
| FB_Sensor_Analog_Processing.st | HIGH | Needed for proper sensor pipeline (raw → processed) |
| FB_Sensor_Calibration_Processor.st | HIGH | Completes calibration pipeline |
| FB_Sensor_Calibration.st | HIGH | Manual/initial calibration logic |

---

## MEDIUM PRIORITY

| Object | Priority | Why |
|---|---|---|
| FB_CO_Detector.st | MEDIUM | Logic duplicated in Gas_Smoke_Manager |
| FB_Gas_Methane_Detector.st | MEDIUM | Same |
| FB_Smoke_Detector.st | MEDIUM | Same |
| FB_Sensor_Distribution.st | MEDIUM | Clean architecture but not required now |
| FB_Maintenance_Access.st | MEDIUM | Feature-ready but not core |

---

## LOW PRIORITY

| Object | Priority | Why |
|---|---|---|
| FB_Presence_Playback.st | LOW | Optional feature |
| FB_Presence_Simulator.st | LOW | Wrapper |
| SNAPSHOT cluster | LOW | Parked |

---

## IGNORE (already stable)

| Object | Reason |
|---|---|
| TREND cluster | Stable |
| LIFETIME cluster | Stable |
| FB_Gas_Smoke_Manager.st | Integrated safety core |

---

## Strategic directions

Sensor pipeline:
Raw IO → Analog Processing → Calibration → Distribution → Safety / Control

Safety:
Gas/Smoke → Valve control integration

UX:
Presence simulation
Maintenance access

---

## Next step

Implement sensor pipeline (HIGH group)

