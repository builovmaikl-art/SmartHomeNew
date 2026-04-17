from pathlib import Path
import re

path = Path("FB_Alarm_Manager.st")
text = path.read_text(encoding="utf-8")

# 1. Удаляем VAR scaffold
patterns_var = [
    r'\s+L_Alarm_V2_.*?:.*?;\n',
    r'\s+L_History_V2_.*?:.*?;\n',
    r'\s+L_BlackBox_V2_.*?:.*?;\n',
    r'\s+L_Alarm_Using_Legacy_Fallback\s*:.*?;\n',
    r'\s+L_Alarm_Shadow_.*?:.*?;\n',
    r'\s+L_Alarm_Compat_.*?:.*?;\n',
]

for p in patterns_var:
    text = re.sub(p, '', text)

# 2. Удаляем INIT блоки
patterns_init = [
    r'L_Alarm_V2_.*?:=.*?;\n',
    r'L_History_V2_.*?:=.*?;\n',
    r'L_BlackBox_V2_.*?:=.*?;\n',
    r'L_Alarm_Using_Legacy_Fallback\s*:=[^;]*;\n',
]

for p in patterns_init:
    text = re.sub(p, '', text)

# 3. Удаляем shadow compare блоки
text = re.sub(
    r'// Shadow comparison.*?END_IF;\n',
    '',
    text,
    flags=re.S
)

# 4. Удаляем History/BlackBox shadow блок
text = re.sub(
    r'// Shadow bridge: Alarm -> History V2.*?END_IF;\n',
    '',
    text,
    flags=re.S
)

text = re.sub(
    r'// Shadow bridge: System -> BlackBox V2.*?\n\n',
    '',
    text,
    flags=re.S
)

# 5. Удаляем validation блок
text = re.sub(
    r'// Shadow validation: History V2 / BlackBox V2.*?END_IF;\n',
    '',
    text,
    flags=re.S
)

# 6. Удаляем Path Ready блок
text = re.sub(
    r'// Guarded V2 pipeline enable:.*?END_IF;\n',
    '',
    text,
    flags=re.S
)

path.write_text(text, encoding="utf-8")
print("OK: removed full V2 scaffold from FB_Alarm_Manager.st")
