# Rule Engine Condition Translation

## Legacy -> V2 source mapping (draft)
- COND_AIR_TEMP -> RULE_SRC_AIR_TEMP
- COND_FLOOR_TEMP -> RULE_SRC_FLOOR_TEMP
- COND_HUMIDITY -> RULE_SRC_HUMIDITY
- COND_CO2 -> RULE_SRC_CO2
- COND_MOTION -> RULE_SRC_MOTION
- COND_DOOR_WINDOW -> RULE_SRC_DOOR / RULE_SRC_WINDOW (requires explicit decision)
- COND_FLOOD -> RULE_SRC_FLOOD
- COND_SMOKE -> RULE_SRC_SMOKE
- COND_METHANE -> RULE_SRC_METHANE
- COND_CO -> RULE_SRC_CO
- COND_TIME_OF_DAY -> RULE_SRC_TIME_OF_DAY
- COND_DAY_OF_WEEK -> RULE_SRC_DAY_OF_WEEK

## Value typing rules
- boolean legacy conditions must set value_type = RULE_VALUE_BOOL
- analog thresholds must set value_type = RULE_VALUE_REAL
- time/day conditions require explicit type handling
