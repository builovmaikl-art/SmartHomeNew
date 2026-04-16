# Encapsulation review

## Scope
- Reviewed `FUNCTION_BLOCK` and `PROGRAM` boundaries in `result.txt`.
- Focused on whether reusable blocks depend on global state directly or receive state through explicit interfaces.

## Summary
- **Programs** (`PROGRAM ...`) are acting as orchestration/composition layers. Direct `GVL_*` access is acceptable there because they assemble system-wide state and wire blocks together.
- **Most domain `FUNCTION_BLOCK`s** are reasonably encapsulated: they mainly operate through `VAR_INPUT` / `VAR_OUTPUT` and only use `GVL_CONSTANTS` for array sizing and limits.
- **One direct runtime global dependency was fixed**: `FB_Astro_Timer` no longer reads `GVL_STATUS.G_Current_TOD` internally and now receives current TOD through its interface.

## Fixed issue
- `FB_Astro_Timer` previously depended on `GVL_STATUS.G_Current_TOD` from inside the block, which made the block less reusable and harder to test in isolation.
- The block now accepts `VI_Current_TOD` as an input, so the caller owns time-context injection.

## Remaining encapsulation hotspots
These blocks still directly access retained/global storage and are the main candidates for follow-up refactoring:

1. `FB_BlackBox_Recorder`
   - Reads/writes `GVL_Retain.G_BlackBox_*` internally.
   - Recommendation: pass recorder storage via `VAR_IN_OUT` or wrap retained storage in a dedicated persistence adapter block.

2. `FB_History_Manager`
   - Writes directly to `GVL_Retain.G_History_*`.
   - Recommendation: move ring-buffer state to explicit `VAR_IN_OUT` storage.

3. `FB_NVRAM_Manager`
   - Uses `GVL_Retain.G_NVRAM_Data` internally.
   - Recommendation: isolate low-level storage access behind a dedicated persistence service and keep this FB interface-based.

4. `FB_Presence_Playback`
   - Reads/writes `GVL_Retain.G_Presence_History`.
   - Recommendation: inject the history buffer instead of accessing retained globals directly.

5. `FB_Valve_Test_Manager`
   - Writes results to `GVL_Retain.G_Valve_Test_Results`.
   - Recommendation: return results through outputs and let a program/service persist them.

## Architectural conclusion
- The codebase is **partially encapsulated well at the control-logic level**, especially for heating, ventilation, lighting, sockets, and security managers.
- The main encapsulation weakness is **embedded persistence/global storage access from inside reusable function blocks**.
- Recommended next step: standardize a pattern where `PROGRAM` layers own `GVL_*` interaction, while `FUNCTION_BLOCK`s receive operational state and persistence buffers only through explicit interfaces.
