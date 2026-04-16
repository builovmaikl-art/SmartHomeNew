FUNCTION_BLOCK FB_Rule_V2_To_Legacy_Adapter_DRAFT
VAR_INPUT
    VI_Rule_V2 : ST_User_Rule_V2;
END_VAR
VAR_OUTPUT
    VO_Rule_Legacy : ST_User_Rule;
    VO_Translation_OK : BOOL;
    VO_Warning_Text : STRING(255);
END_VAR

VO_Translation_OK := TRUE;
VO_Warning_Text := '';

VO_Rule_Legacy.Enabled := VI_Rule_V2.enabled;

CASE VI_Rule_V2.condition.source OF
    E_Rule_Data_Source_V2.RULE_SRC_AIR_TEMP:
        VO_Rule_Legacy.Condition_Type := E_Rule_Condition_Type.COND_AIR_TEMP;
    E_Rule_Data_Source_V2.RULE_SRC_FLOOR_TEMP:
        VO_Rule_Legacy.Condition_Type := E_Rule_Condition_Type.COND_FLOOR_TEMP;
    E_Rule_Data_Source_V2.RULE_SRC_HUMIDITY:
        VO_Rule_Legacy.Condition_Type := E_Rule_Condition_Type.COND_HUMIDITY;
    E_Rule_Data_Source_V2.RULE_SRC_CO2:
        VO_Rule_Legacy.Condition_Type := E_Rule_Condition_Type.COND_CO2;
    E_Rule_Data_Source_V2.RULE_SRC_MOTION:
        VO_Rule_Legacy.Condition_Type := E_Rule_Condition_Type.COND_MOTION;
    E_Rule_Data_Source_V2.RULE_SRC_DOOR:
        VO_Rule_Legacy.Condition_Type := E_Rule_Condition_Type.COND_DOOR_WINDOW;
        VO_Warning_Text := 'V2 door mapped to legacy DOOR_WINDOW';
    E_Rule_Data_Source_V2.RULE_SRC_WINDOW:
        VO_Rule_Legacy.Condition_Type := E_Rule_Condition_Type.COND_DOOR_WINDOW;
        VO_Warning_Text := 'V2 window mapped to legacy DOOR_WINDOW';
    E_Rule_Data_Source_V2.RULE_SRC_FLOOD:
        VO_Rule_Legacy.Condition_Type := E_Rule_Condition_Type.COND_FLOOD;
    E_Rule_Data_Source_V2.RULE_SRC_SMOKE:
        VO_Rule_Legacy.Condition_Type := E_Rule_Condition_Type.COND_SMOKE;
    E_Rule_Data_Source_V2.RULE_SRC_METHANE:
        VO_Rule_Legacy.Condition_Type := E_Rule_Condition_Type.COND_METHANE;
    E_Rule_Data_Source_V2.RULE_SRC_CO:
        VO_Rule_Legacy.Condition_Type := E_Rule_Condition_Type.COND_CO;
    E_Rule_Data_Source_V2.RULE_SRC_TIME_OF_DAY:
        VO_Rule_Legacy.Condition_Type := E_Rule_Condition_Type.COND_TIME_OF_DAY;
    E_Rule_Data_Source_V2.RULE_SRC_DAY_OF_WEEK:
        VO_Rule_Legacy.Condition_Type := E_Rule_Condition_Type.COND_DAY_OF_WEEK;
ELSE
    VO_Translation_OK := FALSE;
    VO_Warning_Text := 'Unsupported V2 condition source';
END_CASE;

VO_Rule_Legacy.Condition_Target_ID := VI_Rule_V2.condition.source_id;
VO_Rule_Legacy.Condition_Op := VI_Rule_V2.condition.comparison;
VO_Rule_Legacy.Condition_Value := VI_Rule_V2.condition.value_real;
VO_Rule_Legacy.Condition_Value_Max := VI_Rule_V2.condition.value_real_max;

CASE VI_Rule_V2.action.target_domain OF
    E_Rule_Target_Domain_V2.RULE_TARGET_SCENARIO:
        VO_Rule_Legacy.Action_Type := E_Rule_Action_Type.ACTION_ACTIVATE_SCENARIO;
    E_Rule_Target_Domain_V2.RULE_TARGET_SOCKET:
        VO_Rule_Legacy.Action_Type := E_Rule_Action_Type.ACTION_SET_SOCKET;
ELSE
    VO_Rule_Legacy.Action_Type := E_Rule_Action_Type.ACTION_NONE;
END_CASE;

VO_Rule_Legacy.Action_Target_ID := VI_Rule_V2.action.target_id;
VO_Rule_Legacy.Action_Value := VI_Rule_V2.action.value_real;
END_FUNCTION_BLOCK
