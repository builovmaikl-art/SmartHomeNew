# Heating Extraction Plan

## Goal
Split current heating logic into explicit command and state paths before runtime integration.

## Extraction targets
1. Command generation path
2. Safety/enable gating
3. Thermal control path
4. Actuator projection path
5. State collection path

## Current package scope
- extraction map only
- V2 refinement of command/state structures
- no runtime patching
