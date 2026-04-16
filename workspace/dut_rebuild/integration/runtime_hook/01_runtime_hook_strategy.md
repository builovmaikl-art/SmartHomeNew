# Runtime Hook Strategy

## Goal
Insert a compatibility bridge around Rule Engine without changing current downstream contracts in one step.

## Principle
1. Keep active FB_Rule_Engine entry point alive
2. Introduce compatibility package alongside it
3. Convert legacy rule definitions to V2 in a controlled boundary
4. Preserve legacy action outputs until downstream migration is ready

## Hook sequence
- legacy rules in
- Legacy->V2 adapter
- future V2 core
- V2->legacy adapter
- legacy action outputs out
