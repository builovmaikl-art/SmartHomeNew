# Ventilation Extraction Plan

## Goal
Split current ventilation logic into explicit command and state paths before runtime integration.

## Extraction targets
1. Command generation path
2. Safety/enable gating
3. Actuator projection path
4. State collection path
5. Alarm/status projection path

## Current package scope
- extraction map only
- V2 refinement of command/state structures
- no runtime patching
