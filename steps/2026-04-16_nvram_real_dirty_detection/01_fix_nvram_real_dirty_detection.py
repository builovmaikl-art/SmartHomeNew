from pathlib import Path

path = Path("FB_NVRAM_Manager.st")
text = path.read_text(encoding="utf-8")

old = """                // Проверка на изменение данных перед записью
                L_Data_Changed := FALSE;
                IF TRUE THEN
                    L_Data_Changed := TRUE;
                END_IF;
                
                IF L_Data_Changed THEN
"""

new = """                // Проверка на изменение данных перед записью
                L_Data_Changed := FALSE;
                FOR L_i := 0 TO VI_DataSize - 1 DO
                    IF GVL_Retain.G_NVRAM_Data[VI_Offset + L_i] <> L_pData[L_i] THEN
                        L_Data_Changed := TRUE;
                        EXIT;
                    END_IF;
                END_FOR;
                
                IF L_Data_Changed THEN
"""

if old not in text:
    raise SystemExit("Target block not found in FB_NVRAM_Manager.st")

text = text.replace(old, new, 1)
path.write_text(text, encoding="utf-8")
print("OK: real dirty detection installed in FB_NVRAM_Manager.st")
