# Requirements traceability note

## Current source status
- The repository currently does **not** contain the referenced file `ТЗ .txt`.
- The attachment/resource was also not available through the configured MCP resources in this environment.
- Because of that, the current review artifacts should be treated as **derived from the implemented model in `result.txt` plus explicit owner corrections from the chat**, not as a final verified transcription of the original technical assignment.

## What is currently considered authoritative
1. The implemented PLC/ST aggregate in `result.txt`.
2. The extracted hardware review artifacts:
   - `io_full_spec.md`
   - `io_capacity_review.md`
   - `io_reviewed_target_spec.md`
   - `encapsulation_review.md`
3. The latest explicit owner corrections, especially:
   - flood sensors only in wet zones,
   - boilers via OpenTherm instead of physical DI/DO/AI/AO,
   - reduced socket groups,
   - one inlet water valve,
   - merged audible alarm,
   - reduced CO2 instrumentation to key rooms.

## Required follow-up once `ТЗ .txt` is available
- Reconcile room list and actual bedroom count.
- Verify wet-zone count and exact flood-sensor placement.
- Verify final boiler integration architecture against the original assignment and later amendments.
- Confirm whether socket groups and CO2 sensors were revised only by change request or already by an updated TЗ revision.
- Recheck whether any safety/perimeter/grouped security loops were intended as mandatory redundancy in the original text.

## Practical implication
- Any BOM, cabinet allocation, or final IO module selection should be marked **preliminary** until the missing `ТЗ .txt` is attached and compared line-by-line with the reviewed target specification.
