# HEATING_ARCHITECTURAL_ANTI_PATTERNS

# Purpose

This document formalizes architectural anti-patterns and governance violations for the heating runtime.

The goal is to prevent:

```text
- architectural drift;
- detached runtime resurrection;
- hidden authority growth;
- duplicate runtime writers;
- unsafe helper escalation;
- telemetry/control coupling;
- governance/control coupling.
```

This document converts accumulated runtime audits into:

```text
long-term architectural protection rules.
```

This document complements:

```text
HEATING_RUNTIME_GOVERNANCE_CLASSIFICATION.md
HEATING_RUNTIME_OWNERSHIP_MATRIX.md
HEATING_GVL_WRITE_AUDIT.md
HEATING_ACTIVE_WRITE_PATH_VERIFICATION.md
```

---

# Core invariant

The invariant that must never be violated:

```text
single active runtime ownership chain
```

Current verified chain:

```text
PRG_Heating
→ FB_Heating_System_Manager
    → Safety_Gate
    → Safe_State
    → Circuit_Control
    → Demand_Map
    → Policy_Priority_Bridge
    → Allocation_Filter
    → Runtime_Observability
    → Manifold_Control
    → System_Manager post-manifold finalization
    → Boiler_Control
```

Any architecture bypassing this chain is a governance violation.

---

# Forbidden architectural patterns

## AP-001 — Detached orchestration runtime

Forbidden:

```text
creating runtime orchestration
outside the active ownership chain
```

Examples:

```text
- parallel orchestration shells;
- detached execution coordinators;
- alternate heating execution runtime;
- hidden runtime supervisors.
```

Reason:

```text
creates second authority path
```

Historical context:

```text
historical orchestration donors were removed from production root
```

---

## AP-002 — Hidden runtime writers

Forbidden:

```text
runtime actuation writes
not explicitly documented as ownership
```

Examples:

```text
- hidden valve writers;
- hidden pump writers;
- hidden OpenTherm writers;
- hidden manifold suppressors.
```

Reason:

```text
creates invisible authority overlap
```

---

## AP-003 — Runtime_* actuation

Forbidden:

```text
Runtime_* family directly controlling runtime outputs
```

Examples:

```text
- Runtime_* valve writes;
- Runtime_* boiler writes;
- Runtime_* OpenTherm writes;
- Runtime_* emergency override ownership.
```

Allowed:

```text
- observability;
- diagnostics;
- telemetry;
- governance validation;
- forensic reconstruction.
```

Reason:

```text
Runtime_* family is governance/observability infrastructure,
not active runtime authority.
```

---

## AP-004 — Telemetry-driven control

Forbidden:

```text
telemetry or analytics layers
performing direct runtime actuation
```

Examples:

```text
- anomaly detector suppressing valves directly;
- telemetry confidence score directly disabling heating;
- diagnostics layer mutating runtime outputs.
```

Allowed:

```text
telemetry publication
without actuation ownership.
```

---

## AP-005 — Governance-driven actuation

Forbidden:

```text
governance scaffold
performing runtime execution
```

Examples:

```text
- Orchestration_Shell writing outputs;
- Coordinator owning pumps;
- Contract_Validator suppressing valves.
```

Required governance locks:

```text
Governance_Locked := TRUE
Runtime_Attachment_Allowed := FALSE
Observation-only semantics
```

---

## AP-006 — Helper authority escalation

Forbidden:

```text
bounded helpers silently becoming runtime owners
```

Examples:

```text
- helper mutating unrelated outputs;
- helper performing hidden arbitration;
- helper performing implicit safety override;
- helper bypassing top-level runtime chain.
```

Allowed:

```text
bounded helper semantics
inside explicit ownership boundaries.
```

Verified acceptable examples:

```text
FB_Boiler_Cascade_Manager
FB_Boiler_OpenTherm_Interface
FB_Valve_Test_Manager
```

Reason:

```text
helpers must remain explicit execution/support layers,
not hidden authority centers.
```

---

## AP-007 — Detached override resurrection

Forbidden:

```text
reintroducing historical detached override semantics
```

Examples:

```text
- detached pump override;
- detached boiler override;
- detached OpenTherm suppression layer;
- detached emergency authority shell.
```

Historical reference:

```text
FB_Heating_Override_Layer
```

Important:

```text
bounded top-level finalization
inside System_Manager
is NOT detached override resurrection.
```

---

## AP-008 — Mixed projection/control layers

Forbidden:

```text
projection and runtime authority
inside the same logical layer
```

Examples:

```text
- observability directly mutating runtime outputs;
- telemetry projection coupled to actuation;
- diagnostics coupled to control ownership.
```

Required separation:

```text
projection
≠
control
```

---

## AP-009 — Implicit safety ownership

Forbidden:

```text
safety semantics spread implicitly
across unrelated helpers
```

Required explicit owners:

```text
FB_Heating_Safety_Gate
FB_Heating_Safe_State
```

Allowed bounded exceptions:

```text
System_Manager post-manifold pressure finalization
inside active runtime chain.
```

---

## AP-010 — Undocumented finalization layers

Forbidden:

```text
runtime output finalization
without explicit documentation
```

Reason:

```text
creates ownership ambiguity
```

Current verified finalization layer:

```text
System_Manager post-manifold safety/test finalization
```

Future rule:

```text
all finalization layers must remain explicit.
```

---

# Required architectural patterns

## RP-001 — Single active ownership chain

Required:

```text
all runtime actuation
must remain inside
single active runtime chain.
```

---

## RP-002 — Explicit helper boundaries

Required:

```text
helper semantics must remain bounded and explicit.
```

Helpers may:

```text
- realize execution;
- transport commands;
- perform bounded arbitration;
- support maintenance/testing.
```

Helpers may NOT:

```text
- become detached authority centers;
- mutate unrelated runtime domains.
```

---

## RP-003 — Explicit override modes

Required:

```text
all override semantics
must be explicit and discoverable.
```

Verified acceptable example:

```text
FB_Valve_Test_Manager
→ explicit VO_Test_Active semantics
```

---

## RP-004 — Explicit finalization ownership

Required:

```text
all output finalization layers
must be explicitly documented.
```

Current verified example:

```text
System_Manager post-manifold safety/test finalization
```

---

## RP-005 — Observability-only Runtime_* scaffold

Required:

```text
Runtime_* family
must remain governance/observability oriented.
```

Allowed:

```text
- telemetry;
- diagnostics;
- sequencing validation;
- governance validation;
- forensic analysis.
```

Forbidden:

```text
runtime actuation.
```

---

## RP-006 — Evidence-based ownership verification

Required:

```text
ownership claims must be validated
against actual write paths.
```

Not:

```text
assumed architecturally.
```

---

# Mandatory governance review triggers

The following changes REQUIRE governance review:

```text
- new runtime writer;
- helper begins mutating outputs;
- new GVL mutation path;
- Runtime_* write expansion;
- new override semantics;
- new finalization layer;
- new OpenTherm arbitration;
- new manifold suppression logic;
- new safety bypass path.
```

---

# Mandatory verification workflow

Before approving any runtime ownership change:

```text
1. verify ownership matrix consistency;
2. verify write-boundary consistency;
3. verify governance classification consistency;
4. verify no detached authority path;
5. verify no Runtime_* actuation;
6. verify no hidden helper escalation;
7. verify evidence-level write paths.
```

---

# Current architectural status

Current evidence indicates:

```text
- detached orchestration runtime removed;
- detached override runtime removed from root;
- Runtime_* family remains governance/observability oriented;
- helper authority escalation not detected;
- hidden Runtime_* actuation not detected;
- active runtime ownership chain appears bounded and explicit.
```

Remaining architectural concern:

```text
future complexity drift
```

rather than:

```text
historical runtime collapse.
```

---

# Strategic conclusion

The repository has evolved from:

```text
legacy orchestration cleanup
```

into:

```text
governed runtime architecture maintenance.
```

The primary goal now is:

```text
prevent future architectural drift
while preserving runtime clarity and bounded ownership.
```
