from pathlib import Path

path = Path("FB_Alarm_Manager.st")
text = path.read_text(encoding="utf-8")

old = "    fbCompatAlarm : ARRAY[1..GVL_CONSTANTS.C_MAX_ALARMS] OF FB_Alarm_Compatibility_Package;\n"
if old not in text:
    raise SystemExit("Unused fbCompatAlarm declaration not found")

text = text.replace(old, "", 1)
path.write_text(text, encoding="utf-8")
print("OK: removed unused fbCompatAlarm declaration")
