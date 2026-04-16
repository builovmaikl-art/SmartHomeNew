# FB INVENTORY AUDIT — BATCH 04

Status: Final Stage 0 audit batch (manager blocks)
Purpose: Close inventory of critical manager-level blocks

---

## 1. FB_Security_System_Manager

Review status: REVIEWED
Primary role: Mixed (Detector + Health + Policy + Actuation)

Current reality:
- reads raw sensors (motion, door, window)
- performs validation and bypass logic
- performs arming/disarming logic
- contains alarm delay timers
- determines alarm activation
- directly controls siren

Confirmed violations:
- ❌ detector logic inside manager
- ❌ health qualification inside block
- ❌ alarm ownership inside block
- ❌ direct actuation (siren)
- ❌ no dependency on System_Health

Disposition:
- Split / Rewrite

Required follow-up:
- extract intrusion detection signals
- move alarm qualification to Health
- move siren control to Policy
- separate authentication/2FA as service

---

## 2. FB_Heating_System_Manager

Review status: REVIEWED
Primary role: Mixed (Policy + Actuation + Diagnostics + Partial State leak)

Current reality:
- partially uses System_Mode (good)
- contains full control logic (PID, valves, pumps)
- contains safety reactions (freeze, gas stop, IO fail-safe)
- writes into GVL_STATE (state leakage)
- processes Rule Engine actions directly

Confirmed violations:
- ❌ direct manipulation of GVL_STATE (state ownership violation)
- ❌ embedded safety logic (should be centralized)
- ❌ consumes Rule Engine actions directly (policy bypass risk)
- ❌ mixes control + safety + diagnostics

Positive aspects:
- ✔ uses System_Mode (correct direction)
- ✔ attempts policy separation (L_Policy_*)

Disposition:
- Split / Refactor (not full rewrite)

Required follow-up:
- isolate policy layer explicitly
- remove direct GVL_STATE writes
- separate safety handling to Health
- keep control algorithms (PID etc.)

---

## 3. Final pattern confirmation

Across ALL manager blocks:

1. Managers combine multiple architectural layers
2. Safety logic is distributed and duplicated
3. Direct actuation exists in many places
4. State leakage via GVL is present

---

## 4. Stage 0 FINAL conclusion

The system is NOT partially broken — it is architecturally inconsistent:

- new architecture introduced
- legacy logic still dominant
- partial migration creates conflicting control paths

This must be resolved by:
- introducing System_Health
- enforcing strict separation
- removing legacy shortcuts

---

## 5. FINAL priority list (locked)

CRITICAL:
1. FB_System_Health (create)
2. FB_State_Manager (rewrite contract)
3. FB_Gas_Smoke_Manager (split)
4. FB_Water_Leakage_Manager (split)

HIGH:
5. FB_Rule_Engine (restrict)
6. Valve controllers (clean)

MEDIUM:
7. Security_System_Manager
8. Heating_System_Manager
9. Ventilation_System_Manager

---

## 6. Stage 0 completion status

✔ All critical FB classes reviewed
✔ Violations confirmed with real code
✔ Patterns identified
✔ Refactor direction defined

Stage 0 is now COMPLETE.

---

End of batch 04
