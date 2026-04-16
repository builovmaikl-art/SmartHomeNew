# Patch Strategy

Phase 1 (safe):
- add adapter call BEFORE evaluation
- do not change outputs
- log warnings only

Phase 2:
- introduce optional switch between legacy and V2 evaluation

Phase 3:
- replace evaluation fully
