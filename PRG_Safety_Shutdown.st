PROGRAM PRG_Safety_Shutdown
VAR
    L_Mode : E_Safety_Mode := NORMAL;
END_VAR

// Input degraded forces safe stop first
IF GVL_INPUT.IN_Input_Degraded THEN
    L_Mode := GLOBAL_STOP;
ELSE

    // Priority: FIRE > GAS > WATER > GLOBAL_STOP > NORMAL

    IF GVL_INTENT_SAFETY.I_Fire_Alarm_Active THEN
        L_Mode := FIRE;
    ELSIF GVL_INTENT_SAFETY.I_Gas_Close_Required THEN
        L_Mode := GAS;
    ELSIF GVL_INTENT_SAFETY.I_Water_Main_Close_Required THEN
        L_Mode := WATER_LEAK;
    ELSIF GVL_INTENT_SAFETY.I_System_Safe_Stop_Required THEN
        L_Mode := GLOBAL_STOP;
    ELSE
        L_Mode := NORMAL;
    END_IF;

END_IF;

GVL_SAFETY_SHUTDOWN.G_Safety_Mode := L_Mode;
GVL_SAFETY_SHUTDOWN.G_Safety_Active := (L_Mode <> NORMAL);

// >>> BULK_SYNC_ANCHOR: PRG_Safety_Shutdown <<<
