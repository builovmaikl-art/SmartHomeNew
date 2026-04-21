from pathlib import Path

path = Path('PRG_Security.st')
text = path.read_text(encoding='utf-8')

old = """FOR L_i := 1 TO 16 DO
    L_Motion_Sensors_16[L_i] := L_Motion_Sensors_16[L_i];
END_FOR;"""

new = """FOR L_i := 1 TO 16 DO
    L_Motion_Sensors_16[L_i] := GVL_STATE.G_Motion_Sensors[L_i];
END_FOR;"""

count = text.count(old)
if count != 1:
    raise SystemExit(f'Expected exactly one motion mapping block, got {count}')

text = text.replace(old, new)
path.write_text(text, encoding='utf-8')
print('OK: fixed motion sensors mapping from GVL_STATE')
