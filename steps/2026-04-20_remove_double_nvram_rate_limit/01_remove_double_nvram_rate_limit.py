#!/usr/bin/env python3
from pathlib import Path

path = Path("FB_NVRAM_Manager.st")
text = path.read_text(encoding="utf-8")

old_var = "    L_Last_Write_Time_MS        : UDINT := 0; // Время последней записи\n"
if old_var not in text:
    raise SystemExit("L_Last_Write_Time_MS declaration not found")
text = text.replace(old_var, "", 1)

old_block = """            // Ограничение частоты записи (не чаще 1 раза в 60 секунд)
            IF (VI_System_Time_MS - L_Last_Write_Time_MS) < 60000 AND L_Last_Write_Time_MS <> 0 THEN
                VO_Error := TRUE;
                VO_ErrorID := 16#150C;
                VO_HMI_Status_Message := 'NVRAM: Превышена частота записи (лимит 1 раз в 60с)';
            ELSE
                // Проверка на изменение данных перед записью
                L_Data_Changed := FALSE;
                FOR L_i := 0 TO VI_DataSize - 1 DO
                    IF GVL_Retain.G_NVRAM_Data[VI_Offset + L_i] <> L_pData[L_i] THEN
                        L_Data_Changed := TRUE;
                        EXIT;
                    END_IF;
                END_FOR;
                
                IF L_Data_Changed THEN
                    // Безопасное копирование (WRITE)
                    FOR L_i := 0 TO VI_DataSize - 1 DO
                        GVL_Retain.G_NVRAM_Data[VI_Offset + L_i] := L_pData[L_i];
                    END_FOR;
                    L_Last_Write_Time_MS := VI_System_Time_MS;
                    VO_HMI_Status_Message := 'NVRAM: Данные успешно сохранены в RETAIN';
                ELSE
                    VO_HMI_Status_Message := 'NVRAM: Данные не изменились, запись пропущена';
                END_IF;
            END_IF;"""

new_block = """            // Проверка на изменение данных перед записью
            L_Data_Changed := FALSE;
            FOR L_i := 0 TO VI_DataSize - 1 DO
                IF GVL_Retain.G_NVRAM_Data[VI_Offset + L_i] <> L_pData[L_i] THEN
                    L_Data_Changed := TRUE;
                    EXIT;
                END_IF;
            END_FOR;
            
            IF L_Data_Changed THEN
                // Безопасное копирование (WRITE)
                FOR L_i := 0 TO VI_DataSize - 1 DO
                    GVL_Retain.G_NVRAM_Data[VI_Offset + L_i] := L_pData[L_i];
                END_FOR;
                VO_HMI_Status_Message := 'NVRAM: Данные успешно сохранены в RETAIN';
            ELSE
                VO_HMI_Status_Message := 'NVRAM: Данные не изменились, запись пропущена';
            END_IF;"""

if old_block not in text:
    raise SystemExit("Internal rate limit block not found")
text = text.replace(old_block, new_block, 1)

path.write_text(text, encoding="utf-8")
print("OK: removed internal 60s rate limit from FB_NVRAM_Manager")
