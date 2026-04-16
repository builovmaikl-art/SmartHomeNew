# Rule Engine old -> new field map

## ST_User_Rule -> ST_User_Rule_V2
- Enabled -> enabled
- Condition_Type -> condition.source (with translation)
- Condition_Target_ID -> condition.source_id
- Condition_Op -> condition.comparison
- Condition_Value -> condition.value_real
- Condition_Value_Max -> condition.value_real_max
- Action_Type -> action.action_type
- Action_Target_ID -> action.target_id
- Action_Value -> action.value_real

## Notes
- old model mixes semantic source and runtime value typing
- V2 separates source, comparison, and value type
- boolean semantics must be explicitly mapped
