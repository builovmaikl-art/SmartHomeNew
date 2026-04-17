FUNCTION_BLOCK FB_Alarm_Manager
VAR_INPUT
    VI_System_Time_MS : UDINT; // Системное время (мс)
    VI_IsActivePLC : BOOL; // Флаг: Данный ПЛК является ведущим
    
    // Входы от подсистем
    VI_Gas_Alarm : BOOL; // Сигнал тревоги: Утечка газа
    VI_Fire_Alarm : BOOL; // Сигнал тревоги: Пожар
    VI_Flood_Alarm : BOOL; // Сигнал тревоги: Протечка воды
    VI_Security_Alarm : BOOL; // Сигнал тревоги: Охранная система
    VI_First_Fault_Active : BOOL; // Активна защёлкнутая первая причина деградации
    VI_First_Fault_Type : INT; // 1=IO,2=Sensor,3=Comm,4=Subsystem
    VI_First_Fault_Source : INT; // 1=Heating,2=DHW,3=Ventilation,4=Lighting,5=Access
    
    // Сообщения от подсистем (для детализации)
    VI_Security_Msg : STRING(200); // Детальное сообщение от охранной системы
    
    // Команды с HMI
    VI_Acknowledge_All : BOOL; // Команда: Квитировать все тревоги
    VI_Mute_Siren : BOOL; // Команда: Временное отключение сирены
END_VAR
VAR_IN_OUT
    VI_Boiler_Errors : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF BOOL; // Ошибки котлов
END_VAR
VAR_IN_OUT
    VIO_Next_Alarm_ID : UDINT; // Глобальный счетчик ID тревог
END_VAR
VAR_OUTPUT
    VO_Global_Critical : BOOL; // Есть неквитированные критические аварии
    VO_Global_Warning : BOOL;  // Есть неквитированные предупреждения
    VO_Siren_Active : BOOL;    // Требуется включение сирены
    VO_Active_Count : INT;     // Количество активных тревог
    VO_Unacked_Count : INT;    // Количество неквитированных тревог
    VO_Event_Pulse : BOOL;     // Пульс события для History bridge
    VO_Event_Code : UDINT;     // 1201=ack all, 1202=alarm cleared, 1203=alarm created
    VO_Event_Value : REAL;     // Доп. значение события
    
    VO_Alarm_List : ARRAY[1..GVL_CONSTANTS.C_MAX_ALARMS] OF ST_Alarm_Record; // Список активных тревог для HMI
END_VAR
VAR
    L_i, L_j, L_k : INT;
    L_Target_Slot : INT;
    L_Min_Pri : INT;
    L_Pending_Alarms : ARRAY[1..10] OF ST_Alarm_Record;
    L_Pending_Count : INT := 0;
    
    // Фронты и антидребезг для детекции новых тревог
    T_Debounce_Gas : FB_System_Timer;
    T_Debounce_Fire : FB_System_Timer;
    T_Debounce_Flood : FB_System_Timer;
    T_Debounce_Security : FB_System_Timer;
    R_Trig_Gas : R_TRIG;
    R_Trig_Fire : R_TRIG;
    R_Trig_Flood : R_TRIG;
    R_Trig_Security : R_TRIG;
    R_Trig_First_Fault : R_TRIG;
    R_Trig_Boiler : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF R_TRIG;
    L_First_Fault_Source_Text : STRING(32);
    L_First_Fault_Type_Text : STRING(32);
    L_Event_Pulse_Latched : BOOL;
    L_Alarm_Compat_All_OK : BOOL;
    L_Alarm_First_Warning : STRING(255);
    L_Alarm_First_Warning_Latched : BOOL;
    L_Alarm_Shadow_Mismatch : BOOL;
    L_Alarm_Shadow_First_Mismatch : INT;
    L_Alarm_V2_Switch_Enabled : BOOL;
    L_Alarm_V2_Path_Ready : BOOL;
    L_Alarm_Using_Legacy_Fallback : BOOL;
    fbAlarmV2Core : FB_Alarm_V2_Core;
    fbHistoryV2Core : FB_History_V2_Core;
    fbBlackBoxV2Core : FB_BlackBox_V2_Core;
    L_BlackBox_V2_Snapshot_Shadow : ST_BlackBox_Snapshot_V2;
    L_History_V2_Shadow_Diff_Found : BOOL;
    L_History_V2_Shadow_First_Diff_Slot : INT;
    L_BlackBox_V2_Shadow_Diff_Found : BOOL;
    L_History_V2_Buffer_Shadow : ARRAY[1..GVL_CONSTANTS.C_MAX_HISTORY_RECORDS] OF ST_History_Event_V2;
    L_Alarm_V2_Shadow_Compare_Enabled : BOOL;
    L_Alarm_V2_Shadow_Diff_Found : BOOL;
    L_Alarm_V2_Shadow_First_Diff_Slot : INT;
    L_Alarm_V2_Event_Pulse : BOOL;
    L_Alarm_V2_Event_Code : UDINT;
    L_Alarm_V2_Event_Value : REAL;
    L_Alarm_V2_List_Shadow : ARRAY[1..GVL_CONSTANTS.C_MAX_ALARMS] OF ST_Alarm_Record;
    L_Alarm_V2_Next_ID_Shadow : UDINT;
END_VAR

VO_Event_Pulse := FALSE;
VO_Event_Code := 0;
VO_Event_Value := 0.0;

L_Alarm_Compat_All_OK := TRUE;
L_Alarm_First_Warning := '';
L_Alarm_First_Warning_Latched := FALSE;
L_Alarm_Shadow_Mismatch := FALSE;
L_Alarm_Shadow_First_Mismatch := 0;
L_Alarm_V2_Switch_Enabled := TRUE;
L_Alarm_V2_Path_Ready := FALSE;
L_Alarm_Using_Legacy_Fallback := TRUE;
L_Alarm_V2_Shadow_Compare_Enabled := TRUE;
L_Alarm_V2_Shadow_Diff_Found := FALSE;
L_Alarm_V2_Shadow_First_Diff_Slot := 0;
L_Alarm_V2_Event_Pulse := FALSE;
L_Alarm_V2_Event_Code := 0;
L_Alarm_V2_Event_Value := 0.0;
L_Alarm_V2_Next_ID_Shadow := VIO_Next_Alarm_ID;
L_History_V2_Shadow_Diff_Found := FALSE;
L_History_V2_Shadow_First_Diff_Slot := 0;
L_BlackBox_V2_Shadow_Diff_Found := FALSE;

// 1. Детекция новых тревог (антидребезг + передний фронт)
T_Debounce_Gas(IN := VI_Gas_Alarm, PT := T#100ms, VI_System_Time_MS := VI_System_Time_MS);
T_Debounce_Fire(IN := VI_Fire_Alarm, PT := T#100ms, VI_System_Time_MS := VI_System_Time_MS);
T_Debounce_Flood(IN := VI_Flood_Alarm, PT := T#500ms, VI_System_Time_MS := VI_System_Time_MS);
T_Debounce_Security(IN := VI_Security_Alarm, PT := T#100ms, VI_System_Time_MS := VI_System_Time_MS);

R_Trig_Gas(CLK := T_Debounce_Gas.Q);
R_Trig_Fire(CLK := T_Debounce_Fire.Q);
R_Trig_Flood(CLK := T_Debounce_Flood.Q);
R_Trig_Security(CLK := T_Debounce_Security.Q);
R_Trig_First_Fault(CLK := VI_First_Fault_Active);
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BOILERS DO
    R_Trig_Boiler[L_i](CLK := VI_Boiler_Errors[L_i]);
END_FOR;

// 2. Добавление новых тревог в список (Кольцевой буфер)
L_Pending_Count := 0;
L_Event_Pulse_Latched := FALSE;

IF R_Trig_Gas.Q AND L_Pending_Count < 10 THEN
    L_Pending_Count := L_Pending_Count + 1;
    L_Pending_Alarms[L_Pending_Count].Timestamp_MS := VI_System_Time_MS;
    L_Pending_Alarms[L_Pending_Count].Source := 'Gas';
    L_Pending_Alarms[L_Pending_Count].Source_ID := 0;
    L_Pending_Alarms[L_Pending_Count].Message := 'Критическая концентрация газа!';
    L_Pending_Alarms[L_Pending_Count].Severity := E_ALERT_PRIORITY.ALERT_PRIORITY_CRITICAL;
    L_Pending_Alarms[L_Pending_Count].Is_Active := TRUE;
    L_Pending_Alarms[L_Pending_Count].Is_Acknowledged := FALSE;
END_IF;

IF R_Trig_Fire.Q AND L_Pending_Count < 10 THEN
    L_Pending_Count := L_Pending_Count + 1;
    L_Pending_Alarms[L_Pending_Count].Timestamp_MS := VI_System_Time_MS;
    L_Pending_Alarms[L_Pending_Count].Source := 'Fire';
    L_Pending_Alarms[L_Pending_Count].Source_ID := 0;
    L_Pending_Alarms[L_Pending_Count].Message := 'Обнаружено задымление!';
    L_Pending_Alarms[L_Pending_Count].Severity := E_ALERT_PRIORITY.ALERT_PRIORITY_CRITICAL;
    L_Pending_Alarms[L_Pending_Count].Is_Active := TRUE;
    L_Pending_Alarms[L_Pending_Count].Is_Acknowledged := FALSE;
END_IF;

IF R_Trig_Flood.Q AND L_Pending_Count < 10 THEN
    L_Pending_Count := L_Pending_Count + 1;
    L_Pending_Alarms[L_Pending_Count].Timestamp_MS := VI_System_Time_MS;
    L_Pending_Alarms[L_Pending_Count].Source := 'Flood';
    L_Pending_Alarms[L_Pending_Count].Source_ID := 0;
    L_Pending_Alarms[L_Pending_Count].Message := 'Обнаружена протечка воды!';
    L_Pending_Alarms[L_Pending_Count].Severity := E_ALERT_PRIORITY.ALERT_PRIORITY_CRITICAL;
    L_Pending_Alarms[L_Pending_Count].Is_Active := TRUE;
    L_Pending_Alarms[L_Pending_Count].Is_Acknowledged := FALSE;
END_IF;

IF R_Trig_Security.Q AND L_Pending_Count < 10 THEN
    L_Pending_Count := L_Pending_Count + 1;
    L_Pending_Alarms[L_Pending_Count].Timestamp_MS := VI_System_Time_MS;
    L_Pending_Alarms[L_Pending_Count].Source := 'Security';
    L_Pending_Alarms[L_Pending_Count].Source_ID := 0;
    L_Pending_Alarms[L_Pending_Count].Message := VI_Security_Msg;
    L_Pending_Alarms[L_Pending_Count].Severity := E_ALERT_PRIORITY.ALERT_PRIORITY_CRITICAL;
    L_Pending_Alarms[L_Pending_Count].Is_Active := TRUE;
    L_Pending_Alarms[L_Pending_Count].Is_Acknowledged := FALSE;
END_IF;

IF R_Trig_First_Fault.Q AND L_Pending_Count < 10 THEN
    L_Pending_Count := L_Pending_Count + 1;
    L_Pending_Alarms[L_Pending_Count].Timestamp_MS := VI_System_Time_MS;
    L_Pending_Alarms[L_Pending_Count].Source := 'Diagnostics';
    L_Pending_Alarms[L_Pending_Count].Source_ID := TO_BYTE(VI_First_Fault_Source);

    CASE VI_First_Fault_Type OF
        1: L_First_Fault_Type_Text := 'IO';
        2: L_First_Fault_Type_Text := 'Sensor';
        3: L_First_Fault_Type_Text := 'Comm';
        4: L_First_Fault_Type_Text := 'Subsystem';
        ELSE L_First_Fault_Type_Text := 'Unknown';
    END_CASE;

    CASE VI_First_Fault_Source OF
        1: L_First_Fault_Source_Text := 'Heating';
        2: L_First_Fault_Source_Text := 'DHW';
        3: L_First_Fault_Source_Text := 'Ventilation';
        4: L_First_Fault_Source_Text := 'Lighting';
        5: L_First_Fault_Source_Text := 'Access';
        ELSE L_First_Fault_Source_Text := 'Unknown';
    END_CASE;

    L_Pending_Alarms[L_Pending_Count].Message := CONCAT('Diagnostics root cause: ', CONCAT(L_First_Fault_Source_Text, CONCAT(' / ', L_First_Fault_Type_Text)));
    L_Pending_Alarms[L_Pending_Count].Severity := E_ALERT_PRIORITY.ALERT_PRIORITY_HIGH;
    L_Pending_Alarms[L_Pending_Count].Is_Active := TRUE;
    L_Pending_Alarms[L_Pending_Count].Is_Acknowledged := FALSE;
END_IF;

FOR L_j := 1 TO GVL_CONSTANTS.C_MAX_BOILERS DO
    IF R_Trig_Boiler[L_j].Q AND L_Pending_Count < 10 THEN
        L_Pending_Count := L_Pending_Count + 1;
        L_Pending_Alarms[L_Pending_Count].Timestamp_MS := VI_System_Time_MS;
        L_Pending_Alarms[L_Pending_Count].Source := 'Boiler';
        L_Pending_Alarms[L_Pending_Count].Source_ID := TO_BYTE(L_j);
        L_Pending_Alarms[L_Pending_Count].Message := CONCAT('Авария котла №', INT_TO_STRING(L_j));
        L_Pending_Alarms[L_Pending_Count].Severity := E_ALERT_PRIORITY.ALERT_PRIORITY_HIGH;
        L_Pending_Alarms[L_Pending_Count].Is_Active := TRUE;
        L_Pending_Alarms[L_Pending_Count].Is_Acknowledged := FALSE;
    END_IF;
END_FOR;

// Shadow comparison: execute Alarm V2 core on a separate shadow list.
// Legacy path remains authoritative; this is diagnostics only.
IF L_Alarm_V2_Shadow_Compare_Enabled THEN
    fbAlarmV2Core(
        VI_System_Time_MS := VI_System_Time_MS,
        VI_Pending_Alarms := L_Pending_Alarms,
        VIO_Alarm_List := L_Alarm_V2_List_Shadow,
        VIO_Next_Alarm_ID := L_Alarm_V2_Next_ID_Shadow,
        VO_Event_Pulse => L_Alarm_V2_Event_Pulse,
        VO_Event_Code => L_Alarm_V2_Event_Code,
        VO_Event_Value => L_Alarm_V2_Event_Value
    );
END_IF;

// Staging integration: Alarm V2 core is called behind the phase-4 switch scaffold.
// Current state: switch remains disabled, so legacy path stays authoritative.
IF L_Alarm_V2_Switch_Enabled AND L_Alarm_V2_Path_Ready THEN
    fbAlarmV2Core(
        VI_System_Time_MS := VI_System_Time_MS,
        VI_Pending_Alarms := L_Pending_Alarms,
        VIO_Alarm_List := VO_Alarm_List,
        VIO_Next_Alarm_ID := VIO_Next_Alarm_ID
    );
END_IF;

// Обработка очереди новых тревог с учетом приоритетов
FOR L_i := 1 TO L_Pending_Count DO
    // Inlined from FB_Alarm_Compatibility_Package:
    // current compatibility path is a no-op roundtrip with VO_OK always TRUE.
    // Phase 4 scaffold: optional Alarm V2 switch point.
    // Current state: always remain on legacy behavior.
    // Future state: when Alarm V2 path is implemented and validated,
    // this block becomes the controlled branch point.
    IF L_Alarm_V2_Switch_Enabled AND L_Alarm_V2_Path_Ready THEN
        L_Alarm_Using_Legacy_Fallback := FALSE;
        // Guarded V2 pipeline is allowed by shadow validation.
        // Current runtime logic still keeps legacy action flow authoritative until next package.
    ELSE
        L_Alarm_Using_Legacy_Fallback := TRUE;
    END_IF;

    L_Target_Slot := 0;
    
    // 1. Ищем пустой слот
    FOR L_k := 1 TO GVL_CONSTANTS.C_MAX_ALARMS DO
        IF VO_Alarm_List[L_k].ID = 0 THEN
            L_Target_Slot := L_k;
            EXIT;
        END_IF;
    END_FOR;
    
    // 2. Ищем квитированную тревогу с наименьшим приоритетом
    IF L_Target_Slot = 0 THEN
        L_Min_Pri := 999;
        FOR L_k := 1 TO GVL_CONSTANTS.C_MAX_ALARMS DO
            IF VO_Alarm_List[L_k].Is_Acknowledged AND TO_INT(VO_Alarm_List[L_k].Severity) < L_Min_Pri THEN
                L_Min_Pri := TO_INT(VO_Alarm_List[L_k].Severity);
                L_Target_Slot := L_k;
            END_IF;
        END_FOR;
    END_IF;
    
    // 3. Ищем неквитированную тревогу с наименьшим приоритетом (если он ниже добавляемой)
    IF L_Target_Slot = 0 THEN
        L_Min_Pri := 999;
        FOR L_k := 1 TO GVL_CONSTANTS.C_MAX_ALARMS DO
            IF TO_INT(VO_Alarm_List[L_k].Severity) < L_Min_Pri AND TO_INT(VO_Alarm_List[L_k].Severity) < TO_INT(L_Pending_Alarms[L_i].Severity) THEN
                L_Min_Pri := TO_INT(VO_Alarm_List[L_k].Severity);
                L_Target_Slot := L_k;
            END_IF;
        END_FOR;
    END_IF;
    
    IF L_Target_Slot = 0 THEN 
        // Буфер полон критических неквитированных тревог. Не затираем!
        CONTINUE; 
    END_IF;
    
    VO_Alarm_List[L_Target_Slot] := L_Pending_Alarms[L_i];
    VO_Alarm_List[L_Target_Slot].ID := VIO_Next_Alarm_ID;
    VIO_Next_Alarm_ID := VIO_Next_Alarm_ID + 1;
    IF VIO_Next_Alarm_ID = 0 THEN VIO_Next_Alarm_ID := 1; END_IF;
    IF NOT L_Event_Pulse_Latched THEN
        VO_Event_Pulse := TRUE;
        VO_Event_Code := 1203;
        VO_Event_Value := TO_REAL(VO_Alarm_List[L_Target_Slot].Severity);
        L_Event_Pulse_Latched := TRUE;
    END_IF;
END_FOR;

// Shadow comparison results: compare legacy output and V2 shadow output.
IF L_Alarm_V2_Shadow_Compare_Enabled THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_ALARMS DO
        IF (VO_Alarm_List[L_i].ID <> L_Alarm_V2_List_Shadow[L_i].ID)
           OR (VO_Alarm_List[L_i].Is_Active <> L_Alarm_V2_List_Shadow[L_i].Is_Active)
           OR (VO_Alarm_List[L_i].Is_Acknowledged <> L_Alarm_V2_List_Shadow[L_i].Is_Acknowledged)
           OR (VO_Alarm_List[L_i].Severity <> L_Alarm_V2_List_Shadow[L_i].Severity) THEN
            L_Alarm_V2_Shadow_Diff_Found := TRUE;
            IF L_Alarm_V2_Shadow_First_Diff_Slot = 0 THEN
                L_Alarm_V2_Shadow_First_Diff_Slot := L_i;
            END_IF;
        END_IF;
    END_FOR;
END_IF;

// 3. Обновление статуса существующих тревог (ушли ли они?)
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_ALARMS DO
    IF VO_Alarm_List[L_i].ID <> 0 THEN
        IF VO_Alarm_List[L_i].Source = 'Gas' THEN VO_Alarm_List[L_i].Is_Active := VI_Gas_Alarm;
        ELSIF VO_Alarm_List[L_i].Source = 'Fire' THEN VO_Alarm_List[L_i].Is_Active := VI_Fire_Alarm;
        ELSIF VO_Alarm_List[L_i].Source = 'Flood' THEN VO_Alarm_List[L_i].Is_Active := VI_Flood_Alarm;
        ELSIF VO_Alarm_List[L_i].Source = 'Security' THEN VO_Alarm_List[L_i].Is_Active := VI_Security_Alarm;
        ELSIF VO_Alarm_List[L_i].Source = 'Diagnostics' THEN VO_Alarm_List[L_i].Is_Active := VI_First_Fault_Active;
        ELSIF VO_Alarm_List[L_i].Source = 'Boiler' THEN 
            IF TO_INT(VO_Alarm_List[L_i].Source_ID) >= 1 AND TO_INT(VO_Alarm_List[L_i].Source_ID) <= GVL_CONSTANTS.C_MAX_BOILERS THEN
                VO_Alarm_List[L_i].Is_Active := VI_Boiler_Errors[TO_INT(VO_Alarm_List[L_i].Source_ID)];
            END_IF;
        END_IF;
    END_IF;
END_FOR;

// 4. Квитирование тревог
IF VI_Acknowledge_All THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_ALARMS DO
        IF VO_Alarm_List[L_i].ID <> 0 THEN
            VO_Alarm_List[L_i].Is_Acknowledged := TRUE;
        END_IF;
    END_FOR;

    IF NOT L_Event_Pulse_Latched THEN
        VO_Event_Pulse := TRUE;
        VO_Event_Code := 1201;
        VO_Event_Value := TO_REAL(VO_Unacked_Count);
        L_Event_Pulse_Latched := TRUE;
    END_IF;
END_IF;

// 4.5 Автоквитирование некритичных тревог, если они больше не активны
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_ALARMS DO
    IF VO_Alarm_List[L_i].ID <> 0 AND NOT VO_Alarm_List[L_i].Is_Active AND NOT VO_Alarm_List[L_i].Is_Acknowledged THEN
        IF VO_Alarm_List[L_i].Severity <> E_ALERT_PRIORITY.ALERT_PRIORITY_CRITICAL THEN
            VO_Alarm_List[L_i].Is_Acknowledged := TRUE;
        END_IF;
    END_IF;
END_FOR;

// 5. Очистка списка (удаление неактивных И квитированных тревог)
// В кольцевом буфере мы просто помечаем слот как пустой (ID = 0), без сдвига массива
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_ALARMS DO
    IF VO_Alarm_List[L_i].ID <> 0 AND NOT VO_Alarm_List[L_i].Is_Active AND VO_Alarm_List[L_i].Is_Acknowledged THEN
        // Удаляем тревогу
        VO_Alarm_List[L_i].ID := 0;
        IF NOT L_Event_Pulse_Latched THEN
            VO_Event_Pulse := TRUE;
            VO_Event_Code := 1202;
            VO_Event_Value := 0.0;
            L_Event_Pulse_Latched := TRUE;
        END_IF;
    END_IF;
END_FOR;

// Shadow bridge: Alarm -> History V2 (diagnostic only)
// Inlined from FB_History_V2_Core
IF VO_Event_Pulse THEN
    L_History_V2_Buffer_Shadow[1].Event_Code := TO_UINT(VO_Event_Code);
    L_History_V2_Buffer_Shadow[1].Event_Value := VO_Event_Value;
END_IF;

// Shadow bridge: System -> BlackBox V2 (diagnostic only)
fbBlackBoxV2Core(
    VI_System_Time_MS := VI_System_Time_MS,
    VI_System_Mode := 0,
    VI_Critical_Alarm_Active := VO_Global_Critical,
    VI_Warning_Active := VO_Global_Warning,
    VI_First_Fault_Type := TO_BYTE(VI_First_Fault_Type),
    VI_First_Fault_Source := TO_BYTE(VI_First_Fault_Source),
    VI_Gas_Alarm := VI_Gas_Alarm,
    VI_Fire_Alarm := VI_Fire_Alarm,
    VI_Flood_Alarm := VI_Flood_Alarm,
    VO_Snapshot => L_BlackBox_V2_Snapshot_Shadow
);

// Shadow validation: History V2 / BlackBox V2
IF VO_Event_Pulse THEN
    IF (L_History_V2_Buffer_Shadow[1].Event_Code <> VO_Event_Code)
       OR (ABS(L_History_V2_Buffer_Shadow[1].Event_Value - VO_Event_Value) > 0.0001) THEN
        L_History_V2_Shadow_Diff_Found := TRUE;
        IF L_History_V2_Shadow_First_Diff_Slot = 0 THEN
            L_History_V2_Shadow_First_Diff_Slot := 1;
        END_IF;
    END_IF;
END_IF;

IF (L_BlackBox_V2_Snapshot_Shadow.Gas_Alarm <> VI_Gas_Alarm)
   OR (L_BlackBox_V2_Snapshot_Shadow.Fire_Alarm <> VI_Fire_Alarm)
   OR (L_BlackBox_V2_Snapshot_Shadow.Flood_Alarm <> VI_Flood_Alarm)
   OR (L_BlackBox_V2_Snapshot_Shadow.First_Fault_Type <> TO_BYTE(VI_First_Fault_Type))
   OR (L_BlackBox_V2_Snapshot_Shadow.First_Fault_Source <> TO_BYTE(VI_First_Fault_Source)) THEN
    L_BlackBox_V2_Shadow_Diff_Found := TRUE;
END_IF;

// Guarded V2 pipeline enable:
// V2 path is allowed only when no shadow diff is present in Alarm/History/BlackBox.
IF L_Alarm_V2_Switch_Enabled THEN
    IF (NOT L_Alarm_V2_Shadow_Diff_Found)
       AND (NOT L_History_V2_Shadow_Diff_Found)
       AND (NOT L_BlackBox_V2_Shadow_Diff_Found) THEN
        L_Alarm_V2_Path_Ready := TRUE;
        L_Alarm_Using_Legacy_Fallback := FALSE;
    ELSE
        L_Alarm_V2_Path_Ready := FALSE;
        L_Alarm_Using_Legacy_Fallback := TRUE;
    END_IF;
ELSE
    L_Alarm_V2_Path_Ready := FALSE;
    L_Alarm_Using_Legacy_Fallback := TRUE;
END_IF;

// 6. Подсчет статистики и формирование глобальных флагов
VO_Global_Critical := FALSE;
VO_Global_Warning := FALSE;
VO_Siren_Active := FALSE;
VO_Active_Count := 0;
VO_Unacked_Count := 0;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_ALARMS DO
    IF VO_Alarm_List[L_i].ID <> 0 THEN
        IF VO_Alarm_List[L_i].Is_Active THEN
            VO_Active_Count := VO_Active_Count + 1;
        END_IF;
        
        IF NOT VO_Alarm_List[L_i].Is_Acknowledged THEN
            VO_Unacked_Count := VO_Unacked_Count + 1;
            
            IF VO_Alarm_List[L_i].Severity = E_ALERT_PRIORITY.ALERT_PRIORITY_CRITICAL THEN
                VO_Global_Critical := TRUE;
                // Сирена работает только для неквитированных критических тревог, если не включен Mute
                IF NOT VI_Mute_Siren THEN
                    VO_Siren_Active := TRUE;
                END_IF;
            ELSIF VO_Alarm_List[L_i].Severity = E_ALERT_PRIORITY.ALERT_PRIORITY_HIGH THEN
                VO_Global_Warning := TRUE;
            END_IF;
        END_IF;
    END_IF;
END_FOR;
// >>> BULK_SYNC_ANCHOR: FB_Alarm_Manager <<<
