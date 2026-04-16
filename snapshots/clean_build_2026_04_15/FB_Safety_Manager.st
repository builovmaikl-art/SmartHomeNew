FUNCTION_BLOCK FB_Safety_Manager
VAR_INPUT
    VI_Gas_Alarm : BOOL;
    VI_Leak_Alarm : BOOL;
    VI_Smoke_Alarm : BOOL;
    VI_Reset : BOOL; // Ручной сброс защёлкнутых safety-аварий оператором
END_VAR
VAR_OUTPUT
    VO_Gas_Latched : BOOL;
    VO_Leak_Latched : BOOL;
    VO_Smoke_Latched : BOOL;
    VO_Emergency_Stop : BOOL;
END_VAR
VAR
    L_Any_Active : BOOL;
END_VAR

// Защёлкиваем аварии независимо друг от друга
IF VI_Gas_Alarm THEN
    VO_Gas_Latched := TRUE;
END_IF;

IF VI_Leak_Alarm THEN
    VO_Leak_Latched := TRUE;
END_IF;

IF VI_Smoke_Alarm THEN
    VO_Smoke_Latched := TRUE;
END_IF;

L_Any_Active := VI_Gas_Alarm OR VI_Leak_Alarm OR VI_Smoke_Alarm;

// Ручной сброс допустим только когда все входные аварийные сигналы уже исчезли
IF VI_Reset AND NOT L_Any_Active THEN
    VO_Gas_Latched := FALSE;
    VO_Leak_Latched := FALSE;
    VO_Smoke_Latched := FALSE;
END_IF;

// Агрегированный аварийный стоп = любая защёлкнутая safety-авария
VO_Emergency_Stop := VO_Gas_Latched OR VO_Leak_Latched OR VO_Smoke_Latched;
END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Safety_Manager <<<
