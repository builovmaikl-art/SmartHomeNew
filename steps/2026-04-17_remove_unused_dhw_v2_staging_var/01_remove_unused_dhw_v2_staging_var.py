from pathlib import Path

path = Path("FB_DHW_Manager.st")
text = path.read_text(encoding="utf-8")

old = "    fbDHWV2Staging : FB_DHW_V2_Staging;\n"
if old not in text:
    raise SystemExit("Unused fbDHWV2Staging declaration not found")

text = text.replace(old, "", 1)
path.write_text(text, encoding="utf-8")
print("OK: removed unused fbDHWV2Staging declaration")
