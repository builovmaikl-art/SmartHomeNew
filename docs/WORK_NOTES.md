# WORK NOTES — SmartHomeNew

## PURPOSE
Operational checklist and context anchor for ongoing analysis and development.
Do not treat as source of truth — decisions must be moved to proper docs.

---

## IN PROGRESS
- Safety flow audit (Gas / Smoke / CO / Water Leak / Heating interaction)
- State aggregation analysis (GVL_STATE, FB_State_Manager)
- Identify all writers of G_Safety_* flags
- Map fail-safe behavior across subsystems

---

## FOUND (FACTS)
- Dedicated safety managers exist: Gas/Smoke, Water Leak
- GVL_STATE acts as normalized system state layer
- GVL_IO separated from logic (good abstraction)
- Heating system manager is highly developed but overloaded
- State aggregation layer is minimal / underdeveloped

---

## RISKS / QUESTIONS
- Multiple sources writing safety flags?
- Is latched vs non-latched consistently handled?
- Any direct IO usage bypassing mapping layer?
- Heating manager violating separation of concerns?

---

## TODO / DEFERRED
- Decompose FB_Heating_System_Manager
- Unify safety state aggregation
- Align water actuator layer with safety logic
- Expand FB_State_Manager into full system state orchestrator

---

## NEXT STEPS
1. Build full safety signal flow map
2. Identify single source of truth for system state
3. Validate fail-safe behavior under IO failure
4. Continue subsystem-by-subsystem maturity audit

## DEFERRED CLEANUP AFTER STATE MANAGER REFACTOR
- Remove duplicated/obsolete system mode logic remnants from `PRG_System.st` if any remain after integration review
- Review `GVL_ALARM` vs `FB_State_Manager` ownership boundaries
- Retire temporary file `FB_State_Manager_MVP.st`
- Re-check scenario/simulation dependencies after full state-manager integration
- Verify no parallel source of truth exists for system mode texts/cause fields
