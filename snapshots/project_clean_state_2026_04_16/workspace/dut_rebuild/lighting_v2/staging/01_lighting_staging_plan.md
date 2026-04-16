# Lighting Staging Plan

## Goal
Introduce a shadow (staging) path for Lighting V2 without affecting runtime.

## Steps
1. Build V2 command/state from legacy signals
2. Run V2 core in parallel
3. Collect shadow outputs
4. Next step: integrate staging into runtime shadow-only
