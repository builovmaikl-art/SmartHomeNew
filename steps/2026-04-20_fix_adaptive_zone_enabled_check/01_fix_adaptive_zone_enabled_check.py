from pathlib import Path

p = Path("FB_Heating_System_Manager.st")
text = p.read_text(encoding="utf-8")

old = """FOR L_Adaptive_Zone_i := 1 TO 8 DO
    IF VI_Zone_Configs[L_Adaptive_Zone_i].enabled THEN
        IF VI_Zone_Configs[L_Adaptive_Zone_i].zone >= 1 AND VI_Zone_Configs[L_Adaptive_Zone_i].zone <= 16 THEN
"""

new = """FOR L_Adaptive_Zone_i := 1 TO 8 DO
    IF VI_Zone_Configs[L_Adaptive_Zone_i].zone >= 1 AND VI_Zone_Configs[L_Adaptive_Zone_i].zone <= 16 THEN
"""

if old not in text:
    raise SystemExit("Expected adaptive enabled-check block not found")

text = text.replace(old, new, 1)

# remove the now-extra nested END_IF;
old_tail = """        END_IF;
    END_IF;
END_FOR;
"""
new_tail = """        END_IF;
END_FOR;
"""
if old_tail in text:
    text = text.replace(old_tail, new_tail, 1)
else:
    raise SystemExit("Expected adaptive block tail not found")

p.write_text(text, encoding="utf-8")
print("OK: replaced nonexistent .enabled check with valid zone-range check")
