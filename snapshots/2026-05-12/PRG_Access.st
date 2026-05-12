PROGRAM PRG_Access
VAR
    fbProjection : FB_Access_Output_Projection;

    L_Mode : E_Safety_Mode;
    L_Now_MS : UDINT;
    L_Elapsed_MS : UDINT;
    L_Pulse_MS : UDINT;

    L_Lock_1_Open : BOOL;
    L_Lock_1_Close : BOOL;
    L_Lock_2_Open : BOOL;
    L_Lock_2_Close : BOOL;
    L_Gate_Open : BOOL;
    L_Wicket_Open : BOOL;

    L_Prev_Lock_1_Open : BOOL;
    L_Prev_Lock_1_Close : BOOL;
    L_Prev_Lock_2_Open : BOOL;
    L_Prev_Lock_2_Close : BOOL;
    L_Prev_Gate_Open : BOOL;
    L_Prev_Wicket_Open : BOOL;

    L_Pulse_Lock_1_Open : BOOL;
    L_Pulse_Lock_1_Close : BOOL;
    L_Pulse_Lock_2_Open : BOOL;
    L_Pulse_Lock_2_Close : BOOL;
    L_Pulse_Gate_Open : BOOL;
    L_Pulse_Wicket_Open : BOOL;

    L_Start_Lock_1_Open_MS : UDINT;
    L_Start_Lock_1_Close_MS : UDINT;
    L_Start_Lock_2_Open_MS : UDINT;
    L_Start_Lock_2_Close_MS : UDINT;
    L_Start_Gate_Open_MS : UDINT;
    L_Start_Wicket_Open_MS : UDINT;
END_VAR

L_Mode := GVL_SAFETY_SHUTDOWN.G_Safety_Mode;
L_Now_MS := GVL_STATUS.G_System_Time_MS;

// Load pulse duration from config with safety clamp
L_Pulse_MS := GVL_CONFIG.G_Access_Pulse_MS;
IF L_Pulse_MS < 100 THEN
    L_Pulse_MS := 100;
ELSIF L_Pulse_MS > 5000 THEN
    L_Pulse_MS := 5000;
END_IF;

L_Lock_1_Open := FALSE;
L_Lock_1_Close := FALSE;
L_Lock_2_Open := FALSE;
L_Lock_2_Close := FALSE;
L_Gate_Open := FALSE;
L_Wicket_Open := FALSE;

CASE L_Mode OF
    FIRE:
        L_Lock_1_Open := GVL_COMMAND_SHADOW.G_Lock_1_Open;
        L_Lock_2_Open := GVL_COMMAND_SHADOW.G_Lock_2_Open;
        L_Gate_Open := GVL_COMMAND_SHADOW.G_Gate_Open;
        L_Wicket_Open := GVL_COMMAND_SHADOW.G_Wicket_Open;

        L_Pulse_Lock_1_Open := FALSE;
        L_Pulse_Lock_1_Close := FALSE;
        L_Pulse_Lock_2_Open := FALSE;
        L_Pulse_Lock_2_Close := FALSE;
        L_Pulse_Gate_Open := FALSE;
        L_Pulse_Wicket_Open := FALSE;

        L_Prev_Lock_1_Open := GVL_COMMAND_SHADOW.G_Lock_1_Open;
        L_Prev_Lock_1_Close := GVL_COMMAND_SHADOW.G_Lock_1_Close;
        L_Prev_Lock_2_Open := GVL_COMMAND_SHADOW.G_Lock_2_Open;
        L_Prev_Lock_2_Close := GVL_COMMAND_SHADOW.G_Lock_2_Close;
        L_Prev_Gate_Open := GVL_COMMAND_SHADOW.G_Gate_Open;
        L_Prev_Wicket_Open := GVL_COMMAND_SHADOW.G_Wicket_Open;

    GAS:
        L_Gate_Open := GVL_COMMAND_SHADOW.G_Gate_Open;

        IF GVL_COMMAND_SHADOW.G_Lock_1_Open AND NOT L_Prev_Lock_1_Open THEN
            L_Pulse_Lock_1_Open := TRUE;
            L_Start_Lock_1_Open_MS := L_Now_MS;
        END_IF;
        IF GVL_COMMAND_SHADOW.G_Lock_2_Open AND NOT L_Prev_Lock_2_Open THEN
            L_Pulse_Lock_2_Open := TRUE;
            L_Start_Lock_2_Open_MS := L_Now_MS;
        END_IF;
        IF GVL_COMMAND_SHADOW.G_Wicket_Open AND NOT L_Prev_Wicket_Open THEN
            L_Pulse_Wicket_Open := TRUE;
            L_Start_Wicket_Open_MS := L_Now_MS;
        END_IF;

        IF L_Pulse_Lock_1_Open THEN
            L_Elapsed_MS := SEL(L_Now_MS >= L_Start_Lock_1_Open_MS, L_Now_MS - L_Start_Lock_1_Open_MS, (4294967295 - L_Start_Lock_1_Open_MS) + L_Now_MS + 1);
            IF L_Elapsed_MS < L_Pulse_MS THEN
                L_Lock_1_Open := TRUE;
            ELSE
                L_Pulse_Lock_1_Open := FALSE;
            END_IF;
        END_IF;

        IF L_Pulse_Lock_2_Open THEN
            L_Elapsed_MS := SEL(L_Now_MS >= L_Start_Lock_2_Open_MS, L_Now_MS - L_Start_Lock_2_Open_MS, (4294967295 - L_Start_Lock_2_Open_MS) + L_Now_MS + 1);
            IF L_Elapsed_MS < L_Pulse_MS THEN
                L_Lock_2_Open := TRUE;
            ELSE
                L_Pulse_Lock_2_Open := FALSE;
            END_IF;
        END_IF;

        IF L_Pulse_Wicket_Open THEN
            L_Elapsed_MS := SEL(L_Now_MS >= L_Start_Wicket_Open_MS, L_Now_MS - L_Start_Wicket_Open_MS, (4294967295 - L_Start_Wicket_Open_MS) + L_Now_MS + 1);
            IF L_Elapsed_MS < L_Pulse_MS THEN
                L_Wicket_Open := TRUE;
            ELSE
                L_Pulse_Wicket_Open := FALSE;
            END_IF;
        END_IF;

        L_Prev_Lock_1_Open := GVL_COMMAND_SHADOW.G_Lock_1_Open;
        L_Prev_Lock_1_Close := GVL_COMMAND_SHADOW.G_Lock_1_Close;
        L_Prev_Lock_2_Open := GVL_COMMAND_SHADOW.G_Lock_2_Open;
        L_Prev_Lock_2_Close := GVL_COMMAND_SHADOW.G_Lock_2_Close;
        L_Prev_Gate_Open := GVL_COMMAND_SHADOW.G_Gate_Open;
        L_Prev_Wicket_Open := GVL_COMMAND_SHADOW.G_Wicket_Open;

ELSE
        IF GVL_COMMAND_SHADOW.G_Lock_1_Open AND NOT L_Prev_Lock_1_Open THEN
            L_Pulse_Lock_1_Open := TRUE;
            L_Start_Lock_1_Open_MS := L_Now_MS;
        END_IF;
        IF GVL_COMMAND_SHADOW.G_Lock_1_Close AND NOT L_Prev_Lock_1_Close THEN
            L_Pulse_Lock_1_Close := TRUE;
            L_Start_Lock_1_Close_MS := L_Now_MS;
        END_IF;
        IF GVL_COMMAND_SHADOW.G_Lock_2_Open AND NOT L_Prev_Lock_2_Open THEN
            L_Pulse_Lock_2_Open := TRUE;
            L_Start_Lock_2_Open_MS := L_Now_MS;
        END_IF;
        IF GVL_COMMAND_SHADOW.G_Lock_2_Close AND NOT L_Prev_Lock_2_Close THEN
            L_Pulse_Lock_2_Close := TRUE;
            L_Start_Lock_2_Close_MS := L_Now_MS;
        END_IF;
        IF GVL_COMMAND_SHADOW.G_Gate_Open AND NOT L_Prev_Gate_Open THEN
            L_Pulse_Gate_Open := TRUE;
            L_Start_Gate_Open_MS := L_Now_MS;
        END_IF;
        IF GVL_COMMAND_SHADOW.G_Wicket_Open AND NOT L_Prev_Wicket_Open THEN
            L_Pulse_Wicket_Open := TRUE;
            L_Start_Wicket_Open_MS := L_Now_MS;
        END_IF;

        IF L_Pulse_Lock_1_Open THEN
            L_Elapsed_MS := SEL(L_Now_MS >= L_Start_Lock_1_Open_MS, L_Now_MS - L_Start_Lock_1_Open_MS, (4294967295 - L_Start_Lock_1_Open_MS) + L_Now_MS + 1);
            IF L_Elapsed_MS < L_Pulse_MS THEN
                L_Lock_1_Open := TRUE;
            ELSE
                L_Pulse_Lock_1_Open := FALSE;
            END_IF;
        END_IF;

        IF L_Pulse_Lock_1_Close THEN
            L_Elapsed_MS := SEL(L_Now_MS >= L_Start_Lock_1_Close_MS, L_Now_MS - L_Start_Lock_1_Close_MS, (4294967295 - L_Start_Lock_1_Close_MS) + L_Now_MS + 1);
            IF L_Elapsed_MS < L_Pulse_MS THEN
                L_Lock_1_Close := TRUE;
            ELSE
                L_Pulse_Lock_1_Close := FALSE;
            END_IF;
        END_IF;

        IF L_Pulse_Lock_2_Open THEN
            L_Elapsed_MS := SEL(L_Now_MS >= L_Start_Lock_2_Open_MS, L_Now_MS - L_Start_Lock_2_Open_MS, (4294967295 - L_Start_Lock_2_Open_MS) + L_Now_MS + 1);
            IF L_Elapsed_MS < L_Pulse_MS THEN
                L_Lock_2_Open := TRUE;
            ELSE
                L_Pulse_Lock_2_Open := FALSE;
            END_IF;
        END_IF;

        IF L_Pulse_Lock_2_Close THEN
            L_Elapsed_MS := SEL(L_Now_MS >= L_Start_Lock_2_Close_MS, L_Now_MS - L_Start_Lock_2_Close_MS, (4294967295 - L_Start_Lock_2_Close_MS) + L_Now_MS + 1);
            IF L_Elapsed_MS < L_Pulse_MS THEN
                L_Lock_2_Close := TRUE;
            ELSE
                L_Pulse_Lock_2_Close := FALSE;
            END_IF;
        END_IF;

        IF L_Pulse_Gate_Open THEN
            L_Elapsed_MS := SEL(L_Now_MS >= L_Start_Gate_Open_MS, L_Now_MS - L_Start_Gate_Open_MS, (4294967295 - L_Start_Gate_Open_MS) + L_Now_MS + 1);
            IF L_Elapsed_MS < L_Pulse_MS THEN
                L_Gate_Open := TRUE;
            ELSE
                L_Pulse_Gate_Open := FALSE;
            END_IF;
        END_IF;

        IF L_Pulse_Wicket_Open THEN
            L_Elapsed_MS := SEL(L_Now_MS >= L_Start_Wicket_Open_MS, L_Now_MS - L_Start_Wicket_Open_MS, (4294967295 - L_Start_Wicket_Open_MS) + L_Now_MS + 1);
            IF L_Elapsed_MS < L_Pulse_MS THEN
                L_Wicket_Open := TRUE;
            ELSE
                L_Pulse_Wicket_Open := FALSE;
            END_IF;
        END_IF;

        L_Prev_Lock_1_Open := GVL_COMMAND_SHADOW.G_Lock_1_Open;
        L_Prev_Lock_1_Close := GVL_COMMAND_SHADOW.G_Lock_1_Close;
        L_Prev_Lock_2_Open := GVL_COMMAND_SHADOW.G_Lock_2_Open;
        L_Prev_Lock_2_Close := GVL_COMMAND_SHADOW.G_Lock_2_Close;
        L_Prev_Gate_Open := GVL_COMMAND_SHADOW.G_Gate_Open;
        L_Prev_Wicket_Open := GVL_COMMAND_SHADOW.G_Wicket_Open;
END_CASE;

fbProjection(
    VI_Lock_1_Open := L_Lock_1_Open,
    VI_Lock_1_Close := L_Lock_1_Close,
    VI_Lock_2_Open := L_Lock_2_Open,
    VI_Lock_2_Close := L_Lock_2_Close,
    VI_Gate_Open := L_Gate_Open,
    VI_Wicket_Open := L_Wicket_Open
);

// >>> BULK_SYNC_ANCHOR: PRG_Access <<<
END_PROGRAM
