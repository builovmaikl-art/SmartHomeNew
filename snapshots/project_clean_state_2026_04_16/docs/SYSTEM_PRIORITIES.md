# SYSTEM PRIORITIES (Subsystem Behavior Rules)

## Purpose
Defines internal priority logic for each subsystem, aligned with POLICY_LAYER.

---

## Global Rule

Policy > Emergency > System Logic > Scenario > User

---

## Ventilation (V2 - Implemented)

### Priority Ladder

1. SAFE_STOP / Fire
2. FREEZE_PROTECTION
3. DEGRADED / Gas
4. Wet Zones (bathroom exhaust)
5. Rule Engine
6. Scenario
7. User

### Notes
- DEGRADED = supply OFF, exhaust LIMITED
- User stop is lowest priority
- Wet zones always preserved unless SAFE_STOP

---

## DHW (In Progress)

### Planned Priority Ladder

1. SAFE_STOP
2. FREEZE_PROTECTION
3. DEGRADED
4. Anti-legionella / safety
5. Heating demand
6. Scenario
7. User

### Notes
- No hard stop unless critical
- Temperature maintenance prioritized over user OFF

---

## Heating (Planned)

### Planned Priority Ladder

1. SAFE_STOP
2. FREEZE_PROTECTION
3. DEGRADED
4. Frost protection loops
5. Room demand
6. Scenario
7. User

---

## Implementation Rules

- No direct overrides bypassing policy
- Each subsystem must expose policy flags
- Degradation preferred over shutdown

---

## Status

Version: v1
Aligned with Ventilation V2 and DHW planning
