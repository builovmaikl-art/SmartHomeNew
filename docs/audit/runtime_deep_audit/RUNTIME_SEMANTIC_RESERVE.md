# Runtime Semantic Reserve

## Purpose

This document records runtime-related semantic structures that must not be treated as ordinary dead code during cleanup.

The current `runtime_dead_semantic_audit.py` detects unused fields and semantic zombie patterns by textual/member-access evidence. That is useful for removing obvious entropy, but it is not sufficient to decide whether systematic observability, explainability, diagnostic, simulation or integration structures should be deleted.

Some structures appear unused in active runtime code while still representing historical or planned architectural work. These structures are now classified as **runtime semantic reserve** until their integration history and intended role are reviewed.

## Current cleanup boundary

GVL cleanup has reduced unused global fields from 151 to 13. The remaining GVL findings are no longer treated as ordinary garbage by default. They are either simulation/test contract surfaces, recovery hooks, future runtime placeholders or compatibility residues that require explicit review.

The next workstream should shift from blind deletion to recovery of missing or partially integrated architectural work.

## Classification model

| Class | Meaning | Action |
|---|---|---|
| `REMOVE_NOW` | Clear dead residue with no runtime, diagnostic or historical contract value. | Delete after audit confirmation. |
| `KEEP_CONTRACT` | Active or intended API/contract surface even if not currently referenced by member access. | Keep and document. |
| `ARCHITECTURAL_RESERVE` | Systematic structure that may represent lost, abandoned or not-yet-integrated design work. | Preserve pending reconstruction review. |
| `FUTURE_RUNTIME` | Placeholder for planned runtime behavior or hardware integration. | Keep until implementation decision. |

## Semantic reserve candidates

### Runtime status and explainability fields

Examples:

- `Status_Code`
- `Status_Text`
- `*_Visible`
- `*_Observation`
- `*_Degraded`
- `*_Attention`
- `*_Valid`

These fields appear repeatedly across runtime metadata, phase events, causality, anomalies, adaptive intelligence and integration bridge DUTs. Their repetition suggests a deliberate observability model rather than random residue.

They may have been intended for:

- online HMI display;
- engineering diagnostics;
- blackbox/event logging;
- explainability output;
- runtime phase/status tracking;
- safety/runtime integration verification;
- post-event reconstruction.

Until historical traces are reviewed, these fields must not be removed solely because they are currently unused by member access.

### Candidate DUT groups for reserve review

The following DUT families should be reviewed as architectural reserve before deletion:

- `ST_Heating_Runtime_Meta_Supervision`
- `ST_Heating_Runtime_Adaptive_Intelligence`
- `ST_Heating_Runtime_Causality_Graph`
- `ST_Heating_Runtime_Causality_Edge`
- `ST_Heating_Runtime_Anomaly`
- `ST_Heating_Runtime_Blackbox_Event`
- `ST_Heating_Runtime_Integration_Bridge`
- `ST_Heating_Runtime_Phase_Event`

These groups should be compared against snapshots and runtime audit documents before cleanup.

## Historical trace expectation

If a reserve structure exists systematically, there should be traces of its intended integration in one or more of:

- `snapshots/`
- historical audit documents;
- runtime deep audit notes;
- previous branch snapshots;
- scaffolding documents;
- integration bridge drafts;
- blackbox/explainability planning documents.

The review process should search for matching type names, field names and conceptual aliases before deciding whether to delete, restore or integrate a structure.

## Remaining GVL reserve after cleanup

The remaining unused GVL fields are currently treated as reserve/contract unless later proven removable:

### Simulation contract surface

- `GVL_SIMULATION.G_Inject_Heating_Sensor_Fault`
- `GVL_SIMULATION.G_Inject_IO_Fault`
- `GVL_SIMULATION.G_Inject_Low_Pressure`
- `GVL_SIMULATION.G_Inject_Predictive_Pump_Fault`
- `GVL_SIMULATION.G_Inject_Gas_Alarm`
- `GVL_SIMULATION.G_Inject_Leak_Alarm`
- `GVL_SIMULATION.G_Inject_Smoke_Alarm`
- `GVL_SIMULATION.G_Inject_Dual_PLC_Active`

These are retained as test-control inputs. A direct production injection bridge is not currently implemented.

### Future runtime / recovery hooks

- `GVL_STATE.G_Water_Zone_Enable`
- `GVL_STATE.G_Water_Zone_Exercise_Active`
- `GVL_SAFETY_RECOVERY.G_Recovery_Exit_Allowed`
- `GVL_SAFETY_RECOVERY_CONFIG.G_Stable_Time_Required_MS`
- `GVL_COMMAND.G_Scenario_Request`

These require separate ownership and integration review.

## Recommended next workstream

Instead of continuing mechanical deletion, the next priority should be **semantic recovery**:

1. Build a focused reserve audit report that lists only semantic zombie and architectural-reserve findings.
2. Search snapshots/history for each reserve DUT family.
3. Classify each family as one of:
   - restore/integrate;
   - document and keep;
   - archive/remove;
   - replace with smaller runtime contract.
4. Recover the useful missing pieces before resuming large-scale DUT cleanup.

## Guardrail

Do not remove systematic runtime observability structures simply because the current code does not read their fields. For these families, lack of member access is a signal for integration review, not an automatic deletion decision.
