# HEATING_ORCHESTRATION_REDESIGN.md

# STATUS

This document defines the mandatory redesign contract for the future heating orchestration layer.

It is based on:
- current verified runtime behavior
- current diagnostics architecture
- current OpenTherm ownership model
- current safety ownership model
- current explainability pipeline

This document is NOT theoretical.
It reflects the currently verified live architecture.

---

# PRIMARY RULE

The future orchestration layer:
- MUST coordinate
- MUST sequence
- MUST route ownership

The orchestration layer:
- MUST NOT become runtime logic duplication
- MUST NOT own diagnostics
- MUST NOT own explainability
- MUST NOT override safety chains directly
- MUST NOT bypass freeze protection
- MUST NOT bypass DHW policy

---

# VERIFIED LIVE RUNTIME CONTRACT

Current live execution order:

1. DHW manager executes first
2. Heating manager executes second
3. Runtime state publication executes third
4. Diagnostics/explainability executes fourth
5. Output projection executes last

This order is now considered mandatory.

Any orchestration redesign violating this order is invalid.

---

# CURRENT RUNTIME OWNERSHIP

## DHW ownership

Owned by:
- FB_DHW_Manager

Responsibilities:
- DHW circulation policy
- DHW heating demand
- DHW temperature regulation
- DHW heating arbitration

The orchestration layer MUST NOT:
- directly override DHW circulation
- directly override DHW heating state
- duplicate DHW arbitration

---

## Heating ownership

Owned by:
- FB_Heating_System_Manager
- FB_Heating_Boiler_Control
- FB_Boiler_Cascade_Manager

Responsibilities:
- manifold logic
- heating demand aggregation
- cascade arbitration
- boiler setpoint generation
- heating fallback logic

The orchestration layer MUST NOT:
- duplicate cascade logic
- duplicate heating arbitration
- duplicate manifold control

---

## OpenTherm ownership

Owned by:
- FB_Boiler_OpenTherm_Interface

Responsibilities:
- command sequencing
- ACK tracking
- heartbeat validation
- adapter transport semantics

The orchestration layer MUST NOT:
- manipulate OT sequence counters
- manipulate transport acknowledgements
- bypass OT command ownership

---

## Diagnostics ownership

Owned by:
- FB_Diagnostics_RootCause
- FB_Heating_RootCause_Diagnostics
- FB_Heating_Diagnostics

Responsibilities:
- inference
- explainability
- diagnostics event projection

The orchestration layer MUST NOT:
- infer diagnostics
- publish root-cause state
- publish explainability state
- own diagnostics events

---

## Explainability ownership

Owned by:
- PRG_Explainability
- PRG_HMI_Dashboard

Responsibilities:
- operator reasoning
- HMI diagnostics projection
- reason-chain publication

The orchestration layer MUST remain downstream-neutral.

---

## Safety ownership

Owned by:
- emergency stop chain
- gas safety chain
- freeze protection chain

The orchestration layer MUST NEVER:
- bypass safety chains
- directly clear safety state
- override freeze protection ownership

---

# WHY THE OLD ORCHESTRATION FAILED

## FB_Heating_Execution_Core

Problems:
- executed heating before DHW
- violated live demand timing semantics
- lacked diagnostics integration
- lacked explainability integration
- lacked modern semantic state integration

Result:
- non-equivalent runtime behavior

---

## FB_Heating_Override_Layer

Problems:
- overly broad override authority
- disabled unrelated subsystems together
- mixed heating and DHW ownership
- could disable freeze fallback devices
- lacked semantic safety awareness

Result:
- unsafe ownership model

---

## FB_Heating_Orchestration

Problems:
- wrapper around outdated execution model
- unaware of layered diagnostics architecture
- unaware of semantic OT state
- unaware of explainability pipeline

Result:
- obsolete orchestration shell

---

# REQUIRED FUTURE ARCHITECTURE

The future orchestration layer must become:

## Coordinator

Responsible for:
- sequencing
- execution routing
- lifecycle coordination
- startup/shutdown ordering

NOT responsible for:
- control logic
- diagnostics
- explainability

---

## Ownership router

Responsible for:
- deciding WHO owns execution rights
- deciding WHICH layer executes
- deciding execution ordering

NOT responsible for:
- calculating temperatures
- calculating diagnostics
- calculating safety decisions

---

## Runtime boundary layer

Responsible for:
- preserving deterministic execution ordering
- preserving PLC scan consistency
- preserving state publication ordering

NOT responsible for:
- semantic interpretation
- diagnostics reasoning

---

# FUTURE SAFE EXTRACTION PLAN

## Stage 1 — COMPLETE

Completed:
- diagnostics layering
- semantic OT diagnostics
- semantic cascade diagnostics
- explainability integration
- HMI diagnostics projection
- ownership mapping
- sequencing contract definition

Status:
- COMPLETE

---

## Stage 2 — PREPARATION

Next safe targets:
- extract runtime sequencing boundaries
- isolate output projection contract
- isolate lifecycle coordination
- isolate execution timing contract

Status:
- READY

---

## Stage 3 — CONTROLLED EXTRACTION

Allowed future extraction candidates:
- startup coordination
- shutdown coordination
- execution scheduling
- mode routing

NOT allowed:
- cascade duplication
- diagnostics duplication
- safety duplication
- OT transport duplication

Status:
- NOT STARTED

---

# CURRENT DECISION

The repository is now considered PREPARED for controlled orchestration redesign.

But:
- runtime migration has NOT started
- orchestration wrappers remain disconnected
- no runtime authority has been moved
- no ownership has been reassigned

This is intentional.
