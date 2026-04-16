FUNCTION_BLOCK FB_Presence_Playback
VAR_INPUT
    VI_Mode_Record : BOOL; // TRUE - записываем, FALSE - воспроизводим
    VI_Time_Index   : UDINT; // Индекс времени в рамках недели (мс)
END_VAR
VAR_IN_OUT
    VI_Light_Inputs : ARRAY[1..32] OF BOOL;
END_VAR
VAR_OUTPUT
    VO_Light_Outputs : ARRAY[1..32] OF BOOL;
END_VAR
VAR
    L_Current_Slot : UDINT;
    L_i : INT;
END_VAR

L_Current_Slot := (VI_Time_Index / (GVL_CONSTANTS.C_MS_IN_MINUTE * 10)) MOD TO_UDINT(GVL_CONSTANTS.C_MAX_PRESENCE_HISTORY); // Слот каждые 10 минут

IF VI_Mode_Record THEN
    // Запись текущего состояния в слот
    GVL_Retain.G_Presence_History[L_Current_Slot] := 0;
    FOR L_i := 1 TO 32 DO
        IF VI_Light_Inputs[L_i] THEN
            GVL_Retain.G_Presence_History[L_Current_Slot] := GVL_Retain.G_Presence_History[L_Current_Slot] OR SHL(WORD#1, L_i-1);
        END_IF;
    END_FOR;
ELSE
    // Воспроизведение из слота
    FOR L_i := 1 TO 32 DO
        VO_Light_Outputs[L_i] := (GVL_Retain.G_Presence_History[L_Current_Slot] AND SHL(WORD#1, L_i-1)) <> 0;
    END_FOR;
END_IF;