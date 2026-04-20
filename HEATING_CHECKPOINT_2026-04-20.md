# HEATING CHECKPOINT — 2026-04-20

## Current verified architecture

The heating path is currently split across these live components:

- `PRG_System`
  - writes `GVL_STATE.G_Preheat_Request`
  - writes `GVL_STATE.G_Freeze_Request`
- `PRG_Heating`
  - reads the above request flags
  - performs heating arbitration / stabilization
  - writes `GVL_STATE.G_Target_Temperature`
  - passes preheat request into `FB_Heating_System_Manager`
- `FB_Heating_System_Manager`
  - consumes the resulting target temperature injection
  - remains the live application point for heating behavior

## Verified design intent

Current heating chain:

`Rule Engine -> PRG_System -> GVL_STATE request flags -> PRG_Heating arbitration/stabilization -> FB_Heating_System_Manager`

## Verified requests / signals

- `GVL_STATE.G_Preheat_Request`
- `GVL_STATE.G_Freeze_Request`
- `GVL_STATE.G_Target_Temperature`

## Important constraints

- Do not create a separate standalone heating request GVL again unless it is proven to be included by the local project.
- Cross-program FB references must not be used between `PRG_System` and `PRG_Heating`.
- New heating behavior should enter through request/arbitration layers, not by direct random writes.

## Current limitations

- Arbitration is still global, not per-zone.
- Stabilization is coarse and not yet production-grade hysteresis.
- No explicit adaptive per-zone policy exists yet.
- Freeze/preheat/normal priorities exist, but their semantics should be documented before further expansion.

## Recommended next large step

Introduce **adaptive / multi-zone heating policy** only after preserving this checkpoint.
That next step should:
- keep `PRG_System -> GVL_STATE -> PRG_Heating -> FB_Heating_System_Manager`
- avoid introducing new standalone command types unless project inclusion is guaranteed
- prefer explicit zone-aware policy over more global flags

## Files touched in this heating evolution

- `PRG_System.st`
- `PRG_Heating.st`
- `FB_Heating_System_Manager.st`
- `GVL_STATE.gvl`



## Heating evolution status update

The heating stack has advanced beyond the earlier checkpoint and now includes:

- request flags in `GVL_STATE`
- arbitration / stabilization in `PRG_Heating`
- target temperature injection in `FB_Heating_System_Manager`
- multi-zone adaptive correction
- weighted adaptive correction
- floor-vs-air adaptive bias
- zone priority weighting

## Current practical interpretation

The current heating path is no longer only a request bridge.
It is now a layered control path:

`Rule Engine -> PRG_System -> GVL_STATE requests -> PRG_Heating arbitration/stabilization -> FB_Heating_System_Manager adaptive weighted correction`

## Recommended next engineering step

Do not merge all remaining adaptation ideas into a single mega-step.
Prefer 2-3 large controlled packages:

1. adaptive v3: per-zone hysteresis / time stability
2. policy refinement: freeze/preheat/normal semantics cleanup
3. optional later tuning: zone classes / comfort policy / learning

