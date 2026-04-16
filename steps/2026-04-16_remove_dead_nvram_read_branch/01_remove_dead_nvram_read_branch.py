from pathlib import Path

path = Path("FB_NVRAM_Manager.st")
text = path.read_text(encoding="utf-8")

old = """        VO_Done := TRUE;
        
    ELSIF VI_Command = 2 THEN // ЧТЕНИЕ (READ)
        // Безопасное копирование (READ)
        FOR L_i := 0 TO VI_DataSize - 1 DO
            L_pData[L_i] := GVL_Retain.G_NVRAM_Data[VI_Offset + L_i];
        END_FOR;
        VO_HMI_Status_Message := 'NVRAM: Данные успешно прочитаны из RETAIN';
        VO_Done := TRUE;
    END_IF;
END_IF;

IF VI_Command = 0 THEN
"""

new = """        VO_Done := TRUE;
    END_IF;
END_IF;

IF VI_Command = 0 THEN
"""

if old not in text:
    raise SystemExit("Target READ branch not found in FB_NVRAM_Manager.st")

text = text.replace(old, new, 1)
path.write_text(text, encoding="utf-8")
print("OK: removed dead READ branch from FB_NVRAM_Manager.st")
