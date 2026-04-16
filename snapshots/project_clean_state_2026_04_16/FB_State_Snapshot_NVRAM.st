FUNCTION_BLOCK FB_State_Snapshot_NVRAM
VAR_INPUT
    VI_System_Time_MS : UDINT;
    VI_Save_Req       : BOOL;
    VI_Snapshot       : ST_State_Snapshot;
END_VAR
VAR_OUTPUT
    VO_Saved          : BOOL;
    VO_Error          : BOOL;
END_VAR
VAR
    L_FileName        : STRING := '/home/root/snapshot.bin';
    L_State           : INT := 0;
    
    // Асинхронные блоки из библиотеки CAA_File
    fbFileOpen        : FILE.Open;
    fbFileWrite       : FILE.Write;
    fbFileClose       : FILE.Close;
    L_FileHandle      : FILE.HANDLE;
END_VAR

CASE L_State OF
    0: // Ожидание
        VO_Saved := FALSE;
        VO_Error := FALSE;
        IF VI_Save_Req THEN
            L_State := 10;
            fbFileOpen(xExecute := FALSE);
            fbFileWrite(xExecute := FALSE);
            fbFileClose(xExecute := FALSE);
        END_IF;
        
    10: // Открытие файла
        fbFileOpen(
            xExecute := TRUE,
            sFileName := L_FileName,
            eFileMode := FILE.MODE.MWRITE
        );
        IF fbFileOpen.xDone THEN
            L_FileHandle := fbFileOpen.hFile;
            fbFileOpen(xExecute := FALSE);
            L_State := 20;
        ELSIF fbFileOpen.xError THEN
            VO_Error := TRUE;
            L_State := 0;
        END_IF;
        
    20: // Запись
        fbFileWrite(
            xExecute := TRUE,
            hFile := L_FileHandle,
            pBuffer := ADR(VI_Snapshot),
            szSize := SIZEOF(VI_Snapshot)
        );
        IF fbFileWrite.xDone THEN
            fbFileWrite(xExecute := FALSE);
            L_State := 30;
        ELSIF fbFileWrite.xError THEN
            VO_Error := TRUE;
            L_State := 30; // Все равно закрываем файл
        END_IF;
        
    30: // Закрытие
        fbFileClose(
            xExecute := TRUE,
            hFile := L_FileHandle
        );
        IF fbFileClose.xDone THEN
            fbFileClose(xExecute := FALSE);
            IF NOT VO_Error THEN
                VO_Saved := TRUE;
            END_IF;
            L_State := 0;
        ELSIF fbFileClose.xError THEN
            VO_Error := TRUE;
            L_State := 0;
        END_IF;
END_CASE;