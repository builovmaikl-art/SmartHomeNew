FUNCTION_BLOCK FB_Access_Pulse_Channel
VAR_INPUT
    VI_Command : BOOL;
    VI_Reset : BOOL;
    VI_Now_MS : UDINT;
    VI_Pulse_MS : UDINT;
END_VAR
VAR_OUTPUT
    VO_Output : BOOL;
    VO_Active : BOOL;
END_VAR
VAR
    L_Prev_Command : BOOL;
    L_Start_MS : UDINT;
    L_Elapsed_MS : UDINT;
END_VAR

IF VI_Reset THEN
    VO_Output := FALSE;
    VO_Active := FALSE;
    L_Prev_Command := VI_Command;
    L_Start_MS := VI_Now_MS;
    RETURN;
END_IF;

IF VI_Command AND NOT L_Prev_Command THEN
    VO_Active := TRUE;
    L_Start_MS := VI_Now_MS;
END_IF;

VO_Output := FALSE;

IF VO_Active THEN
    IF VI_Now_MS >= L_Start_MS THEN
        L_Elapsed_MS := VI_Now_MS - L_Start_MS;
    ELSE
        L_Elapsed_MS := (4294967295 - L_Start_MS) + VI_Now_MS + 1;
    END_IF;

    IF L_Elapsed_MS < VI_Pulse_MS THEN
        VO_Output := TRUE;
    ELSE
        VO_Active := FALSE;
    END_IF;
END_IF;

L_Prev_Command := VI_Command;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Access_Pulse_Channel <<<
