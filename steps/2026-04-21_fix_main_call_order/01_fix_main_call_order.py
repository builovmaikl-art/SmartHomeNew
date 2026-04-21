from pathlib import Path

path = Path('MAIN.st')
text = path.read_text(encoding='utf-8')

old = """PROGRAM MAIN
VAR
END_VAR

// Вызов основных программ
PRG_IO_Read();
PRG_Policy();
PRG_System();
PRG_Safety();
PRG_Security();
PRG_Heating();
PRG_Ventilation();
PRG_Lighting();
PRG_IO_Write();

// PRG_Test(); // Раскомментировать для запуска модульных тестов"""

new = """PROGRAM MAIN
VAR
END_VAR

// Вызов основных программ
PRG_IO_Read();
PRG_Safety();
PRG_System();
PRG_Policy();
PRG_Security();
PRG_Heating();
PRG_Ventilation();
PRG_Lighting();
PRG_IO_Write();

// PRG_Test(); // Раскомментировать для запуска модульных тестов"""

count = text.count(old)
if count != 1:
    raise SystemExit(f'Expected exactly one MAIN block, got {count}')

text = text.replace(old, new)
path.write_text(text, encoding='utf-8')
print('OK: reordered MAIN call order to IO_Read -> Safety -> System -> Policy -> Managers -> IO_Write')
