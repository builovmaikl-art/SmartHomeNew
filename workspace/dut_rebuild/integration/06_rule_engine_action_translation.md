# Rule Engine Action Translation

## Legacy -> V2 target domain mapping (draft)
- ACTION_ACTIVATE_SCENARIO -> RULE_TARGET_SCENARIO
- ACTION_SET_LIGHT -> RULE_TARGET_LIGHTING
- ACTION_SET_BLINDS -> RULE_TARGET_BLINDS
- ACTION_SET_SOCKET / ACTION_TOGGLE_SOCKET -> RULE_TARGET_SOCKET
- heating-related actions -> RULE_TARGET_HEATING
- ventilation-related actions -> RULE_TARGET_VENTILATION

## Notes
- target domain and action type must not remain implicitly coupled
- boolean/toggle semantics must stay explicit at adapter boundary
