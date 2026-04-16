# Rule Engine Integration Plan (Controlled)

## Goal
Introduce V2 rule data model without breaking active runtime.

## Strategy
1. Keep old DUT untouched initially
2. Add compatibility mapping old -> new in workspace first
3. Prepare adapter layer for Rule Engine input/output
4. Migrate Rule Engine internals only after adapter is frozen
5. Migrate downstream consumers later

## Phase A — Compatibility freeze
- map ST_User_Rule -> ST_User_Rule_V2
- map ST_Rule_Action -> ST_Rule_Action_V2
- freeze enum translation

## Phase B — Adapter design
- design rule reader adapter
- design action writer adapter
- avoid direct dependency on old structure inside future engine core

## Phase C — Engine split
- extract data provider
- extract condition evaluators
- extract typed action model

## Constraint
No runtime migration until compatibility layer is reviewed.
