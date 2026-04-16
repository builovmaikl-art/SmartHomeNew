# Rule Engine Adapter Draft

## Goal
Introduce a compatibility adapter between old active DUT and V2 DUT in workspace only.

## Scope
No runtime integration yet.
No changes to active FB_Rule_Engine.

## Adapter responsibilities
1. Read legacy ST_User_Rule
2. Translate to ST_User_Rule_V2
3. Translate V2 action back to legacy ST_Rule_Action when needed
4. Keep enum/domain mapping explicit

## Required outputs
- old_to_new_condition_translation table
- old_to_new_action_translation table
- adapter function block draft
- unresolved semantic mismatches list
