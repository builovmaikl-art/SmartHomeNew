# HEATING_CONTROLLED_EXTRACTION_PLAN.md

# PURPOSE

This document defines the FIRST SAFE extraction boundaries for the future heating orchestration redesign.

The purpose is:
- reduce future refactor risk
- preserve runtime determinism
- preserve ownership boundaries
- avoid accidental runtime divergence

This document is intentionally conservative.

---

# IMPORTANT RULE

At this stage:
- NO runtime migration is allowed
- NO orchestration integration is allowed
- NO cascade migration is allowed
- NO OpenTherm ownership migration is allowed

Only:
- extraction boundaries
- sequencing contracts
- lifecycle contracts
- projection contracts

may be prepared.

---

# CURRENT LIVE RUNTIME MODEL

Current runtime structure:

PRG_Heating
    -> FB_DHW_Manager
    -> FB_Heating_System_Manager
    -> service/failsafe gating
    -> runtime state publication
    -> diagnostics observer
    -> output projection

This runtime currently works correctly.

The redesign MUST preserve:
- deterministic scan ordering
- DHW-first semantics
- diagnostics-after-publication semantics
- output-projection-last semantics

---

# SAFE EXTRACTION CANDIDATES

The following areas are considered LOW RISK for future extraction.

---

## Candidate 1 — Lifecycle Coordination

Current responsibilities inside PRG_Heating:
- startup ordering
- execution ordering
- execution sequencing
- runtime coordination

This logic is orchestration-safe because:
- it does NOT own heating algorithms
- it does NOT own cascade logic
- it does NOT own OT transport
- it does NOT own diagnostics inference

Potential future target:
- FB_Heating_Runtime_Coordinator

Allowed responsibilities:
- execution order
- execution phase transitions
- startup/shutdown coordination
- execution scheduling

Forbidden responsibilities:
- temperature calculations
- diagnostics generation
- OT sequencing
- safety ownership
- override ownership

Status:
- SAFE FOR FUTURE EXTRACTION
- extraction NOT started yet

---

## Candidate 2 — Output Projection Contract

Current responsibilities:
- projection of runtime decisions to outputs
- projection of manifold outputs
- projection of DHW outputs
- projection of backup/freeze outputs

Current owner:
- FB_Heating_Output_Projection

This layer is already relatively isolated.

This makes it a good orchestration boundary candidate.

Potential future target:
- runtime output contract layer

Allowed future orchestration role:
- call ordering only
- projection sequencing only

Forbidden:
- output calculation
- output arbitration
- diagnostics ownership
- safety ownership

Status:
- SAFE FOR FUTURE EXTRACTION
- extraction NOT started yet

---

# HIGH-RISK EXTRACTION AREAS

The following areas are currently considered DANGEROUS for extraction.

---

## Cascade Logic

Blocks:
- FB_Heating_Boiler_Control
- FB_Boiler_Cascade_Manager

Reasons:
- tightly coupled to thermal semantics
- tightly coupled to DHW demand timing
- tightly coupled to OpenTherm state
- tightly coupled to failover logic

Current decision:
- DO NOT EXTRACT
- DO NOT WRAP
- DO NOT DUPLICATE

---

## OpenTherm Transport

Block:
- FB_Boiler_OpenTherm_Interface

Reasons:
- owns ACK semantics
- owns heartbeat semantics
- owns transport timing
- owns command sequencing

Current decision:
- STRICT SINGLE OWNERSHIP
- orchestration layer must remain transport-neutral

---

## Diagnostics Stack

Blocks:
- FB_Diagnostics_RootCause
- FB_Heating_RootCause_Diagnostics
- FB_Heating_Diagnostics

Reasons:
- already layered correctly
- already decoupled from runtime
- currently stable

Current decision:
- KEEP SEPARATE
- DO NOT MERGE INTO ORCHESTRATION

---

## Safety Chains

Chains:
- gas safety
- emergency stop
- freeze protection

Reasons:
- must remain authoritative
- must remain independent
- must remain deterministic

Current decision:
- orchestration layer must NEVER bypass safety ownership

---

# REQUIRED FUTURE EXTRACTION STYLE

Future extraction must be:
- incremental
- reversible
- ownership-safe
- sequencing-safe
- diagnostics-safe
- transport-safe

Extraction must NEVER:
- duplicate runtime logic
- fork runtime semantics
- duplicate cascade logic
- duplicate OT state
- duplicate diagnostics

---

# FUTURE PHASE MODEL

## Phase 1 — COMPLETE

Completed:
- diagnostics layering
- explainability layering
- semantic OT diagnostics
- semantic cascade diagnostics
- ownership mapping
- redesign contract definition

Status:
- COMPLETE

---

## Phase 2 — CURRENT

Current preparation:
- extraction boundary definition
- orchestration safety definition
- lifecycle ownership mapping
- projection ownership mapping

Status:
- ACTIVE

---

## Phase 3 — FUTURE

Potential future work:
- runtime coordinator extraction
- lifecycle coordinator extraction
- output contract extraction

Strict requirement:
- runtime equivalence verification required before integration

Status:
- NOT STARTED

---

# CURRENT CONCLUSION

The project is now considered PREPARED for controlled extraction.

But:
- the live runtime remains authoritative
- PRG_Heating remains runtime owner
- orchestration wrappers remain disconnected
- no behavioral migration has occurred

This is intentional and correct.
