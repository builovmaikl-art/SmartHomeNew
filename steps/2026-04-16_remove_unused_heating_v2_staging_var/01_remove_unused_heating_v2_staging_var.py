from pathlib import Path

path = Path("FB_Heating_System_Manager.st")
text = path.read_text(encoding="utf-8")

old = "    fbHeatingV2Staging : FB_Heating_V2_Staging;\n"
if old not in text:
    raise SystemExit("Unused fbHeatingV2Staging declaration not found")

text = text.replace(old, "", 1)
path.write_text(text, encoding="utf-8")
print("OK: removed unused fbHeatingV2Staging declaration")
