FUNCTION_BLOCK FB_Rule_Legacy_To_V2_Adapter_DRAFT
VAR_INPUT
    VI_Rule_Legacy : ST_User_Rule;
END_VAR
VAR_OUTPUT
    VO_Rule_V2 : ST_User_Rule_V2;
    VO_Translation_OK : BOOL;
    VO_Warning_Text : STRING(255);
END_VAR

VO_Translation_OK := TRUE;
VO_Warning_Text := '';

VO_Rule_V2.enabled := VI_Rule_Legacy.Enabled;
VO_Rule_V2.name := 'LEGACY_RULE';

CASE VI_Rule_Legacy.Condition_Type OF
    E_Rule_Condition_Type.COND_AIR_TEMP:
        VO_Rule_V2.condition.source := E_Rule_Data_Source_V2.RULE_SRC_AIR_TEMP;
        VO_Rule_V2.condition.value_type := E_Rule_Value_Type_V2.RULE_VALUE_REAL;
    E_Rule_Condition_Type.COND_FLOOR_TEMP:
        VO_Rule_V2.condition.source := E_Rule_Data_Source_V2.RULE_SRC_FLOOR_TEMP;
        VO_Rule_V2.condition.value_type := E_Rule_Value_Type_V2.RULE_VALUE_REAL;
    E_Rule_Condition_Type.COND_HUMIDITY:
        VO_Rule_V2.condition.source := E_Rule_Data_Source_V2.RULE_SRC_HUMIDITY;
        VO_Rule_V2.condition.value_type := E_Rule_Value_Type_V2.RULE_VALUE_REAL;
    E_Rule_Condition_Type.COND_CO2:
        VO_Rule_V2.condition.source := E_Rule_Data_Source_V2.RULE_SRC_CO2;
        VO_Rule_V2.condition.value_type := E_Rule_Value_Type_V2.RULE_VALUE_REAL;
    E_Rule_Condition_Type.COND_MOTION:
        VO_Rule_V2.condition.source := E_Rule_Data_Source_V2.RULE_SRC_MOTION;
        VO_Rule_V2.condition.value_type := E_Rule_Value_Type_V2.RULE_VALUE_BOOL;
    E_Rule_Condition_Type.COND_DOOR_WINDOW:
        VO_Rule_V2.condition.source := E_Rule_Data_Source_V2.RULE_SRC_DOOR;
        VO_Rule_V2.condition.value_type := E_Rule_Value_Type_V2.RULE_VALUE_BOOL;
        VO_Warning_Text := 'Legacy COND_DOOR_WINDOW mapped to RULE_SRC_DOOR by draft adapter';
    E_Rule_Condition_Type.COND_FLOOD:
        VO_Rule_V2.condition.source := E_Rule_Data_Source_V2.RULE_SRC_FLOOD;
        VO_Rule_V2.condition.value_type := E_Rule_Value_Type_V2.RULE_VALUE_BOOL;
    E_Rule_Condition_Type.COND_SMOKE:
        VO_Rule_V2.condition.source := E_Rule_Data_Source_V2.RULE_SRC_SMOKE;
        VO_Rule_V2.condition.value_type := E_Rule_Value_Type_V2.RULE_VALUE_BOOL;
    E_Rule_Condition_Type.COND_METHANE:
        VO_Rule_V2.condition.source := E_Rule_Data_Source_V2.RULE_SRC_METHANE;
        VO_Rule_V2.condition.value_type := E_Rule_Value_Type_V2.RULE_VALUE_REAL;
    E_Rule_Condition_Type.COND_CO:
        VO_Rule_V2.condition.source := E_Rule_Data_Source_V2.RULE_SRC_CO;
        VO_Rule_V2.condition.value_type := E_Rule_Value_Type_V2.RULE_VALUE_REAL;
    E_Rule_Condition_Type.COND_TIME_OF_DAY:
        VO_Rule_V2.condition.source := E_Rule_Data_Source_V2.RULE_SRC_TIME_OF_DAY;
        VO_Rule_V2.condition.value_type := E_Rule_Value_Type_V2.RULE_VALUE_TIME_MINUTES;
    E_Rule_Condition_Type.COND_DAY_OF_WEEK:
        VO_Rule_V2.condition.source := E_Rule_Data_Source_V2.RULE_SRC_DAY_OF_WEEK;
        VO_Rule_V2.condition.value_type := E_Rule_Value_Type_V2.RULE_VALUE_ENUM;
ELSE
    VO_Translation_OK := FALSE;
    VO_Warning_Text := 'Unsupported legacy condition type';
END_CASE;

VO_Rule_V2.condition.enabled := VI_Rule_Legacy.Enabled;
VO_Rule_V2.condition.source_id := VI_Rule_Legacy.Condition_Target_ID;
VO_Rule_V2.condition.comparison := VI_Rule_Legacy.Condition_Op;
VO_Rule_V2.condition.value_real := VI_Rule_Legacy.Condition_Value;
VO_Rule_V2.condition.value_real_max := VI_Rule_Legacy.Condition_Value_Max;
VO_Rule_V2.condition.value_bool := (VI_Rule_Legacy.Condition_Value > 0.5);

CASE VI_Rule_Legacy.Action_Type OF
    E_Rule_Action_Type.ACTION_ACTIVATE_SCENARIO:
        VO_Rule_V2.action.target_domain := E_Rule_Target_Domain_V2.RULE_TARGET_SCENARIO;
    E_Rule_Action_Type.ACTION_SET_SOCKET,
    E_Rule_Action_Type.ACTION_TOGGLE_SOCKET:
        VO_Rule_V2.action.target_domain := E_Rule_Target_Domain_V2.RULE_TARGET_SOCKET;
ELSE
    VO_Rule_V2.action.target_domain := E_Rule_Target_Domain_V2.RULE_TARGET_NONE;
END_CASE;

VO_Rule_V2.action.active := FALSE;
VO_Rule_V2.action.triggered := FALSE;
VO_Rule_V2.action.action_type := VI_Rule_Legacy.Action_Type;
VO_Rule_V2.action.target_id := VI_Rule_Legacy.Action_Target_ID;
VO_Rule_V2.action.value_real := VI_Rule_Legacy.Action_Value;
VO_Rule_V2.action.value_bool := (VI_Rule_Legacy.Action_Value > 0.5);
END_FUNCTION_BLOCK
