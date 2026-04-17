from pathlib import Path

path = Path("FB_Alarm_Manager.st")
text = path.read_text(encoding="utf-8")

old = "    fbHistoryV2Core : FB_History_V2_Core;\n"
if old not in text:
    raise SystemExit("Unused fbHistoryV2Core declaration not found")

text = text.replace(old, "", 1)
path.write_text(text, encoding="utf-8")
print("OK: removed unused fbHistoryV2Core declaration")
