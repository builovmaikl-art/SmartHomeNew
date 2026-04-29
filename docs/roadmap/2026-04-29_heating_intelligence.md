# Heating System Intelligence Roadmap

**Date:** 2026-04-29
**Scope:** Evolution from control logic → intelligent system behavior
**Status:** Design phase

---

# 1. Diagnostics / Fault Tree Layer

## Goal
Move from simple error flags to root-cause analysis.

## Concept
Instead of:
- "Boiler error"

System builds causal chain:

```
No heating → No flow → Pump stopped → IO module offline
```

## Architecture

- FB_Diagnostics_RootCause
- FB_Diagnostics_Flow_Check
- FB_Diagnostics_Thermal_Check
- FB_Diagnostics_IO_Check

## Output

- Root cause (ENUM)
- Confidence level
- Recommended action

## Example

```
RootCause: MANIFOLD_PUMP_FAILURE
Action: Disable manifold #2, redistribute load
```

---

# 2. Policy Layer (Behavior Modes)

## Goal
Separate *decision strategy* from control logic.

## Modes

- NORMAL
- DEGRADED
- FREEZE_PROTECT
- GUEST_PREHEAT
- MAINTENANCE
- ENERGY_SAVE (without tariff dependency)

## Architecture

- FB_Heating_Policy_Manager
- FB_Heating_Mode_Resolver

## Inputs

- System state
- Diagnostics
- User intent

## Outputs

- Target temperature adjustments
- Priority biases
- Subsystem enable/disable

## Example

```
Mode: DEGRADED
→ Reduce heating zones
→ Prioritize critical rooms
```

---

# 3. Comfort Intelligence Layer

## Goal
Adapt heating behavior to building thermal inertia.

## Concepts

- Thermal lag detection
- Overshoot prevention
- Predictive warm-up

## Architecture

- FB_Thermal_Model (lightweight)
- FB_Comfort_Controller

## Inputs

- Historical temps
- Outdoor temp trend
- Heating response

## Outputs

- Adaptive supply temp correction
- Preheat timing

## Example

```
Room heats slowly → start heating earlier
```

---

# 4. Predictive Maintenance

## Goal
Detect degradation before failure.

## Signals

- Pump current drift
- Valve response time
- Boiler modulation anomalies
- Sensor noise

## Architecture

- FB_Anomaly_Detector
- FB_Trend_Analyzer

## Output

- Early warning
- Time-to-failure estimate

## Example

```
Pump current +20% over baseline → possible wear
```

---

# 5. Implementation Order

1. Diagnostics (foundation)
2. Policy layer
3. Comfort intelligence
4. Predictive maintenance

---

# 6. Integration Principles

- No changes to existing control loops
- All intelligence layers = advisory + override-safe
- Deterministic fallback always available

---

# 7. Target Architecture

```
PRG_Heating
│
├── Policy Layer
├── Diagnostics Layer
├── Comfort Layer
├── Control Layer (existing)
└── Safety Layer (existing)
```

---

# 8. Notes

- System must remain deterministic
- No ML black-box logic
- All decisions explainable

---

# Status

Ready for implementation phase (Diagnostics first)
