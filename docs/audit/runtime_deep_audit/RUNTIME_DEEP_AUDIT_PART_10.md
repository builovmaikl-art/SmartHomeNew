# RUNTIME_DEEP_AUDIT_PART_10

# RISK-040

## Runtime verifier executes after physical IO write

Severity:

```text
CRITICAL
```

### Runtime mechanics

Execution order in `MAIN`:

```text
PRG_IO_Write();
PRG_Command_Verifier();
```

This means:

```text
physical outputs are published
before runtime verification executes.
```

At the same time `PRG_Command_Verifier` performs real runtime safety checks against already-published physical outputs:

```text
- gas valve closed validation;
- smoke exhaust verification;
- supply fan shutdown verification;
- freeze circulation verification;
- inactive PLC output verification;
- water valve shutdown verification.
```

---

### Trigger conditions

- arbitration/runtime divergence;
- stale transport mutation;
- same-cycle semantic corruption;
- degraded overlap;
- unsafe transient output generation.

---

### Failure chain

```text
unsafe runtime output generated
↓
PRG_IO_Write publishes physical outputs
↓
unsafe physical state exists in real world
↓
PRG_Command_Verifier detects violation
↓
violation already physically occurred
```

---

### Consequences

```text
- one-cycle unsafe physical output;
- verifier too late to prevent actuation;
- diagnostics-after-fact behavior;
- catastrophic timing-chain exposure;
- physical safety violation before rejection;
- transient unsafe output publication.
```

---

### Why this is critical

Verifier currently behaves as:

```text
diagnostic-after-fact layer
```

instead of:

```text
pre-output authoritative safety barrier.
```

This creates:

```text
same-cycle physical unsafe window.
```

Especially dangerous together with:

```text
- RISK-015 execution-validity divergence;
- RISK-037 scan-cycle visibility gaps;
- RISK-038 post-arbitration transport mutation;
- transport reconnect transients;
- degraded/recovery overlaps.
```

---

### Corrective directions

```text
- move verifier before PRG_IO_Write;
- introduce pre-output safety barrier;
- block physical IO publication on failed verification;
- introduce cycle-stable command snapshots;
- separate diagnostics verifier from safety verifier.
```

---

### Verification strategy

Need explicit tests for:

```text
- same-cycle unsafe command mutation;
- transport mutation after arbitration;
- verifier rejection before IO publication;
- degraded overlap during output generation;
- transient invalid output suppression.
```

---

# RISK-041

## Diagnostics and HMI observe runtime corruption only after physical actuation

Severity:

```text
CRITICAL
```

### Runtime mechanics

Execution order in `MAIN`:

```text
PRG_IO_Write
↓
PRG_Command_Verifier
↓
PRG_System_Health
↓
PRG_System_Diagnostics
↓
PRG_System_BlackBox
↓
PRG_HMI_Dashboard
```

Diagnostics, health, blackbox and HMI layers execute only after:

```text
- domain execution;
- physical IO publication;
- runtime verifier execution.
```

---

### Trigger conditions

- same-cycle unsafe output;
- reconnect mutation;
- degraded overlap;
- transient runtime corruption;
- impossible-state entry.

---

### Failure chain

```text
runtime corruption occurs
↓
unsafe physical outputs already published
↓
diagnostics/health layers execute later
↓
HMI still temporarily shows healthy semantics
↓
operator observes outdated runtime truth
```

---

### Consequences

```text
- HMI displays stale healthy-state;
- diagnostics lag behind unsafe runtime;
- blackbox/history records event too late;
- operators observe semantically outdated truth;
- transient catastrophic outputs not visible in time;
- false-safe operator decisions.
```

---

### Why this is critical

System creates:

```text
false-safe observability window.
```

During this window:

```text
runtime is already unsafe,
but observability layers
still imply valid/safe behavior.
```

Especially dangerous together with:

```text
- RISK-040 verifier-after-IO execution;
- RISK-037 scan-cycle visibility gaps;
- RISK-039 impossible-state survivability;
- reconnect/recovery transients;
- delayed diagnostics publication.
```

---

### Corrective directions

```text
- introduce pre-actuation safety observability barrier;
- create authoritative runtime snapshot before IO publication;
- separate safety-critical diagnostics from post-fact analytics;
- publish emergency runtime state before physical IO commit;
- add real-time unsafe-state signaling path.
```

---

### Verification strategy

Need explicit tests for:

```text
- same-cycle unsafe output visibility;
- HMI stale-safe windows;
- delayed diagnostics propagation;
- transient catastrophic event capture;
- unsafe runtime publication latency.
```

---

### Remediation status — 2026-05-13

Status:

```text
PARTIALLY MITIGATED
```

Implemented cleanup:

```text
- `PRG_System_Diagnostics` no longer calls `FB_System_Diagnostics` as a duplicate aggregate diagnostics writer.
- Aggregated diagnostics ownership for `Sensor_Fault`, `IO_Offline` and `Subsystem_Degraded` is consolidated in `FB_System_Health_Orchestrator`.
- `PRG_System_Diagnostics` state tracing no longer reads stale `GVL_ALARM.*_Alarm_Active` inputs.
- State tracing now uses current `GVL_HEALTH_BRIDGE` safety truth for gas/CO and leak visibility.
- `FB_System_Alarm_Orchestrator` now routes gas/fire/flood alarm inputs from `GVL_HEALTH_BRIDGE` instead of stale `GVL_ALARM.*_Alarm_Active` fields.
```

Risk reduction:

```text
- reduced stale-safe observability windows;
- removed duplicate diagnostics aggregation path;
- removed stale alarm truth from observability traces;
- improved single-source safety truth propagation.
```

Remaining exposure:

```text
- physical output ordering must still be proven through pre-output verifier/barrier path;
- HMI/blackbox timing still requires final verification after output hard-stop proof;
- semantic progress watchdog coverage is tracked under RISK-046.
```

---

# RISK-043

## Recovery completion clears recovery flags but not systemic semantic residue

Severity:

```text
HIGH
```

### Runtime mechanics

`PRG_Safety_Recovery` resets only recovery-control flags during successful completion:

```text
G_Recovery_Phase := IDLE
G_Recovery_Active := FALSE
G_Recovery_Requested := FALSE
G_Recovery_Manual_Confirm := FALSE
```

During `ABORTED` phase only:

```text
G_Recovery_Active := FALSE
```

is reset.

No authoritative cleanup was found for:

```text
- degraded semantic residue;
- runtime sanity error state;
- stale subsystem authority;
- transport recovery residue;
- persistence/replay residue;
- diagnostics stale-fault residue;
- failed recovery context.
```

---

### Trigger conditions

- repeated degraded recovery;
- reconnect instability;
- failed recovery attempts;
- stale persistence state;
- partial subsystem convergence.

---

### Failure chain

```text
fault/degraded state occurs
↓
recovery phase completes
↓
local recovery flags reset
↓
runtime continues execution
↓
stale semantic residue may remain active elsewhere
```

---

### Consequences

```text
- false-clean recovery;
- latent degraded-state fossilization;
- stale authority survival;
- repeated recovery degradation;
- uptime-dependent semantic corrosion.
```

---

### Why this is dangerous

System demonstrates:

```text
good escalation capability
```

but weak:

```text
semantic cleanup guarantees.
```

This creates:

```text
runtime semantic scar accumulation.
```

Especially dangerous together with:

```text
- RISK-042 false recovery convergence;
- persistence replay semantics;
- reconnect instability;
- distributed degraded ownership;
- missing invariant enforcement.
```

---

### Corrective directions

```text
- introduce authoritative runtime cleanup epochs;
- invalidate stale degraded semantics;
- reset subsystem authority during recovery;
- separate recovery completion from cleanup completion;
- add semantic residue diagnostics.
```

---

### Verification strategy

Need explicit tests for:

```text
- repeated degraded recovery cycles;
- reconnect/recovery accumulation;
- stale authority persistence;
- recovery after impossible-state;
- long-uptime semantic drift.
```

---

### Remediation status — 2026-05-13

Status:

```text
PARTIALLY MITIGATED
```

Implemented cleanup:

```text
- `FB_System_Recovery` no longer restores `GVL_STATE.G_Safety_*_Latched` directly from `GVL_PERSISTENT`.
- `FB_System_Recovery` no longer restores `GVL_STATE.G_System_Mode` directly from `GVL_PERSISTENT`.
- Recovery is reduced to a one-shot bootstrap marker; authoritative safety and mode state is reconstructed from runtime truth through orchestrators/managers.
- `FB_System_Health_Orchestrator` now drives `FB_Safety_Manager` from `GVL_HEALTH_BRIDGE` safety truth instead of stale `GVL_STATE.G_Safety_*_Alarm` inputs.
```

Risk reduction:

```text
- removed boot-time stale safety latch resurrection;
- removed boot-time stale system mode resurrection;
- removed persistent direct authority injection;
- improved recovery determinism and runtime ownership separation.
```

Remaining exposure:

```text
- recovery phase-specific cleanup in `PRG_Safety_Recovery` still requires a separate pass;
- degraded convergence and watchdog escalation paths still require writer-graph validation;
- runtime cleanup epoch design remains open.
```

---

# RISK-044

## PLC arbitration lacks authoritative ownership epoch and fencing model

Severity:

```text
CRITICAL
```

### Runtime mechanics

`PRG_PLC_Arbitration` performs arbitration using:

```text
- heartbeat presence;
- last_seen timeout;
- PLC ID comparison.
```

Core logic:

```text
IF NOT Remote_Alive
    → local becomes active
ELSE
    → lowest PLC ID wins
```

However no authoritative mechanism was found for:

```text
- ownership epochs;
- fencing tokens;
- stale-owner invalidation;
- generation/version arbitration;
- split-brain prevention.
```

---

### Trigger conditions

- reconnect after network partition;
- delayed heartbeat recovery;
- stale transport visibility;
- partial PLC restart;
- arbitration oscillation.

---

### Failure chain

```text
PLC-A active
↓
network partition/reconnect occurs
↓
PLC-B temporarily becomes active
↓
stale heartbeat/order recovers
↓
old authority semantically resurrects
↓
runtime ownership becomes ambiguous
```

---

### Consequences

```text
- split-brain runtime authority;
- stale controller resurrection;
- dual ownership semantics;
- arbitration oscillation;
- conflicting physical outputs;
- catastrophic multi-controller behavior.
```

---

### Why this is critical

Current arbitration assumes:

```text
heartbeat visibility
≈ authoritative ownership truth.
```

But distributed runtime recovery requires:

```text
authoritative ownership invalidation semantics.
```

Without fencing/epochs:

```text
old authority may silently return.
```

Especially dangerous together with:

```text
- reconnect instability;
- stale transport semantics;
- degraded recovery overlap;
- snapshot absence;
- impossible-state survivability.
```

---

### Corrective directions

```text
- introduce ownership epochs;
- implement fencing tokens;
- invalidate stale authorities after failover;
- add split-brain detection barrier;
- separate liveness from ownership validity.
```

---

### Verification strategy

Need explicit tests for:

```text
- network partition recovery;
- delayed heartbeat replay;
- stale ownership resurrection;
- dual-controller arbitration;
- reconnect oscillation scenarios.
```

---

# RISK-045

## Арбитраж PLC не защищён от асимметричной видимости heartbeat

Severity:

```text
CRITICAL
```

### Runtime mechanics

В `PRG_PLC_Arbitration` каждый PLC принимает решение локально на основании:

```text
G_Remote_PLC_Pulse
G_Remote_PLC_Last_Seen_MS
G_Remote_PLC_Alive
G_Local_PLC_ID
G_Active_PLC_ID
```

Критично:

```text
G_Remote_PLC_Alive
вычисляется локально
по локальному last_seen.
```

Это позволяет ситуации:

```text
PLC-A считает PLC-B alive
PLC-B считает PLC-A dead
```

или наоборот.

Не найдено:

```text
- quorum/consensus;
- mutual ownership confirmation;
- asymmetric partition detection;
- bidirectional liveness proof;
- split-brain suppression window.
```

---

### Trigger conditions

```text
- асимметричный network partition;
- one-sided packet loss;
- delayed heartbeat delivery;
- transport half-recovery;
- reconnect race.
```

---

### Failure chain

```text
heartbeat visibility becomes asymmetric
↓
PLC-A computes remote alive
↓
PLC-B computes remote dead
↓
both execute different ownership logic
↓
runtime authority diverges
```

---

### Consequences

```text
- asymmetric split-brain;
- dual-active control windows;
- one-sided failover;
- conflicting runtime ownership;
- nondeterministic physical outputs;
- catastrophic controller disagreement.
```

---

### Почему это критично

Сейчас система предполагает:

```text
local heartbeat visibility
≈ global ownership truth.
```

Но при distributed recovery:

```text
локальная видимость
не гарантирует
глобальную согласованность ownership.
```

Это создаёт:

```text
asymmetric split-brain risk.
```

Особенно опасно вместе с:

```text
- RISK-044 stale authority resurrection;
- reconnect instability;
- transport lag;
- отсутствием fencing tokens;
- отсутствием ownership epochs.
```

---

### Corrective directions

```text
- ввести bidirectional ownership confirmation;
- добавить asymmetric partition detection;
- реализовать quorum/fencing semantics;
- разделить liveness и ownership validity;
- добавить split-brain suppression barrier.
```

---

### Verification strategy

```text
- asymmetric packet loss;
- one-sided heartbeat visibility;
- reconnect under partial partition;
- split-brain failover simulation;
- delayed heartbeat replay.
```

---

# RISK-046

## Система считает liveness эквивалентом semantic validity runtime

Severity:

```text
CRITICAL
```

### Runtime mechanics

Текущая архитектура heavily relies on:

```text
- heartbeat;
- pulse;
- timeout;
- alive checks.
```

Однако почти не найдено механизмов проверки:

```text
semantic execution integrity.
```

Не обнаружено:

```text
- cycle execution watchdog;
- semantic progress watchdog;
- execution starvation detector;
- stale output invalidation;
- runtime phase timeout barrier;
- partial-freeze detection.
```

В результате:

```text
runtime может быть
semantically invalid,
но всё ещё considered alive.
```

---

### Trigger conditions

```text
- runtime overload;
- brownout;
- partial execution starvation;
- timer drift;
- degraded scheduling collapse;
- delayed execution phases.
```

---

### Failure chain

```text
runtime overload/brownout occurs
↓
execution phases partially starve
↓
heartbeat still alive
↓
arbitration still trusts PLC
↓
stale/invalid runtime semantics survive
↓
system continues acting on corrupted execution state
```

---

### Consequences

```text
- semantically dead but authoritative PLC;
- stale outputs remain active;
- invalid arbitration decisions;
- delayed verifier execution;
- false healthy-state visibility;
- catastrophic degraded-runtime behavior.
```

---

### Почему это критично

Сейчас система предполагает:

```text
runtime executes
≈ runtime semantically valid.
```

Но для industrial distributed runtime:

```text
alive
не означает
correctly progressing.
```

Это создаёт:

```text
semantic brownout survivability.
```

Особенно опасно вместе с:

```text
- RISK-040 verifier-after-IO;
- RISK-041 observability lag;
- RISK-044 stale authority resurrection;
- RISK-045 asymmetric visibility.
```

---

### Corrective directions

```text
- внедрить semantic progress watchdog;
- контролировать cycle execution deadlines;
- добавить stale-output invalidation;
- реализовать execution starvation detection;
- разделить liveness и semantic validity.
```

---

### Verification strategy

```text
- overload execution tests;
- brownout simulation;
- delayed execution phase injection;
- partial runtime freeze;
- stale output survivability tests.
```

---

### Remediation status — 2026-05-13

Status:

```text
PARTIALLY MITIGATED
```

Implemented cleanup:

```text
- ownership cleanup removed multiple hidden writer paths that could mask semantic invalidity as healthy state;
- `GVL_HEALTH_BRIDGE` is now the consistent safety truth input for alarm aggregation, safety latches and state trace visibility;
- duplicate diagnostics aggregate writer was removed from `PRG_System_Diagnostics`;
- persistent recovery no longer resurrects stale safety/mode state after boot;
- OpenTherm and heating runtime projections have clearer single-writer ownership.
```

Risk reduction:

```text
- reduced stale semantic survivability;
- reduced hidden mutation ambiguity;
- improved separation between liveness, health truth and authoritative state;
- improved foundation for semantic progress watchdog validation.
```

Remaining exposure:

```text
- watchdog escalation path still requires active writer graph review;
- semantic progress watchdog / execution starvation detection still require explicit implementation or proof;
- degraded convergence guarantees still require source-specific ownership validation.
```
