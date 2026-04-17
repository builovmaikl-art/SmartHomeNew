from pathlib import Path

path = Path("FB_Lighting_Blinds_Manager.st")
text = path.read_text(encoding="utf-8")

old = "    fbBlindsV2Staging : FB_Blinds_V2_Staging;\n"
if old not in text:
    raise SystemExit("Unused fbBlindsV2Staging declaration not found")

text = text.replace(old, "", 1)
path.write_text(text, encoding="utf-8")
print("OK: removed unused fbBlindsV2Staging declaration")
