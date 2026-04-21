from pathlib import Path

path = Path('MAIN.st')
text = path.read_text(encoding='utf-8')

old = """PROGRAM MAIN\r\nVAR\r\nEND_VAR\r\n\r\n// Вызов основных программ\r\nPRG_IO_Read();\r\nPRG_Safety();\r\nPRG_System();\r\nPRG_Policy();\r\nPRG_Security();\r\nPRG_Heating();\r\nPRG_Ventilation();\r\nPRG_Lighting();\r\nPRG_IO_Write();\r\n\r\n// PRG_Test(); // Раскомментировать для запуска модульных тестов"""

new = """PROGRAM MAIN\r\nVAR\r\nEND_VAR\r\n\r\n// Вызов основных программ\r\nPRG_IO_Read();\r\nPRG_Safety();\r\nPRG_System();\r\nPRG_Policy();\r\nPRG_Command_Arbitration();\r\nPRG_Command_Verifier();\r\nPRG_Security();\r\nPRG_Heating();\r\nPRG_Ventilation();\r\nPRG_Lighting();\r\nPRG_IO_Write();\r\n\r\n// PRG_Test(); // Раскомментировать для запуска модульных тестов"""

count = text.count(old)
if count != 1:
    raise SystemExit(f'Expected exactly one MAIN block, got {count}')

path.write_text(text.replace(old, new), encoding='utf-8')
print('OK: enabled PRG_Command_Arbitration and PRG_Command_Verifier in MAIN')
