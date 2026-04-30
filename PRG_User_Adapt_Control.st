PROGRAM PRG_User_Adapt_Control
VAR
    fbTrace : FB_Trace_Write;
    L_Text : STRING(64);
END_VAR

IF GVL_INTENT_USER.I_Set_Adapt_Profile_Req THEN

    IF (GVL_INTENT_USER.I_Set_Adapt_Profile_Confirm)
       AND (GVL_INTENT_USER.I_User_Access_Level >= 2) THEN

        GVL_BEHAVIOR_ADAPT.G_Adapt_Profile :=
            GVL_INTENT_USER.I_Adapt_Profile_Value;

        IF GVL_INTENT_USER.I_Adapt_Profile_Value = ADAPT_PROFILE_STABLE THEN
            L_Text := 'Adapt profile: STABLE';
        ELSIF GVL_INTENT_USER.I_Adapt_Profile_Value = ADAPT_PROFILE_BALANCED THEN
            L_Text := 'Adapt profile: BALANCED';
        ELSE
            L_Text := 'Adapt profile: AGGRESSIVE';
        END_IF;

        fbTrace(
            iLayer := TRACE_USER,
            iSource := SRC_USER,
            iReason := REASON_USER_REQUEST,
            iValueBool := TRUE,
            iValueReal := TO_REAL(GVL_INTENT_USER.I_User_Access_Level),
            iText := L_Text
        );

    END_IF;

    GVL_INTENT_USER.I_Set_Adapt_Profile_Req := FALSE;
    GVL_INTENT_USER.I_Set_Adapt_Profile_Confirm := FALSE;

END_IF;
