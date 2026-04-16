FUNCTION_BLOCK FB_Rule_Compatibility_Package_DRAFT
VAR_INPUT
    VI_Rule_Legacy : ST_User_Rule;
END_VAR
VAR_OUTPUT
    VO_Rule_Legacy_Roundtrip : ST_User_Rule;
    VO_Forward_OK : BOOL;
    VO_Reverse_OK : BOOL;
    VO_Warning_Text : STRING(255);
END_VAR
VAR
    fbForward : FB_Rule_Legacy_To_V2_Adapter_DRAFT;
    fbReverse : FB_Rule_V2_To_Legacy_Adapter_DRAFT;
    L_Warn_Forward : STRING(255);
    L_Warn_Reverse : STRING(255);
END_VAR

fbForward(
    VI_Rule_Legacy := VI_Rule_Legacy,
    VO_Rule_V2 => fbReverse.VI_Rule_V2,
    VO_Translation_OK => VO_Forward_OK,
    VO_Warning_Text => L_Warn_Forward
);

fbReverse(
    VO_Rule_Legacy => VO_Rule_Legacy_Roundtrip,
    VO_Translation_OK => VO_Reverse_OK,
    VO_Warning_Text => L_Warn_Reverse
);

IF L_Warn_Forward <> '' THEN
    VO_Warning_Text := L_Warn_Forward;
ELSIF L_Warn_Reverse <> '' THEN
    VO_Warning_Text := L_Warn_Reverse;
ELSE
    VO_Warning_Text := '';
END_IF;
END_FUNCTION_BLOCK
