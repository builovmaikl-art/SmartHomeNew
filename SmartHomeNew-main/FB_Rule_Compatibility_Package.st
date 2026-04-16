FUNCTION_BLOCK FB_Rule_Compatibility_Package
VAR_INPUT
    VI_Rule_Legacy : ST_User_Rule;
END_VAR
VAR_OUTPUT
    VO_Forward_OK : BOOL;
    VO_Reverse_OK : BOOL;
    VO_Warning_Text : STRING(255);
    VO_Rule_Legacy_Roundtrip : ST_Rule;
END_VAR

VO_Forward_OK := TRUE;
VO_Reverse_OK := TRUE;
VO_Warning_Text := '';

VO_Rule_Legacy_Roundtrip.Action_Type := VI_Rule_Legacy.Action_Type;
VO_Rule_Legacy_Roundtrip.Action_Target_ID := VI_Rule_Legacy.Action_Target_ID;
VO_Rule_Legacy_Roundtrip.Action_Value := VI_Rule_Legacy.Action_Value;
VO_Rule_Legacy_Roundtrip.Condition_Type := VI_Rule_Legacy.Condition_Type;
VO_Rule_Legacy_Roundtrip.Condition_Target_ID := VI_Rule_Legacy.Condition_Target_ID;
VO_Rule_Legacy_Roundtrip.Condition_Op := VI_Rule_Legacy.Condition_Op;
VO_Rule_Legacy_Roundtrip.Condition_Value := VI_Rule_Legacy.Condition_Value;
VO_Rule_Legacy_Roundtrip.Condition_Value_Max := VI_Rule_Legacy.Condition_Value_Max;
END_FUNCTION_BLOCK
