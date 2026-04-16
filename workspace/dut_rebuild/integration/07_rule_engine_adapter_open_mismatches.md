# Rule Engine Adapter Open Mismatches

1. Legacy COND_DOOR_WINDOW merges door and window semantics
2. Legacy action value uses one generic numeric channel
3. Legacy bool conditions are represented through numeric comparisons in places
4. Legacy target domain is implicit in action type
5. Downstream consumers still expect legacy ST_Rule_Action
