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
