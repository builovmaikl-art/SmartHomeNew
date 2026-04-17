from pathlib import Path

path = Path("FB_Alarm_Manager.st")
text = path.read_text(encoding="utf-8")

old = "    fbBlackBoxV2Core : FB_BlackBox_V2_Core;\n"
if old not in text:
    raise SystemExit("Unused fbBlackBoxV2Core declaration not found")

text = text.replace(old, "", 1)
path.write_text(text, encoding="utf-8")
print("OK: removed unused fbBlackBoxV2Core declaration")
