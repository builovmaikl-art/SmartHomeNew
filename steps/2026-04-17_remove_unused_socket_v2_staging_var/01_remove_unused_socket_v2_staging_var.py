from pathlib import Path

path = Path("FB_Socket_Manager.st")
text = path.read_text(encoding="utf-8")

old = "    fbSocketV2Staging : FB_Socket_V2_Staging;\n"
if old not in text:
    raise SystemExit("Unused fbSocketV2Staging declaration not found")

text = text.replace(old, "", 1)
path.write_text(text, encoding="utf-8")
print("OK: removed unused fbSocketV2Staging declaration")
