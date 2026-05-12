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
