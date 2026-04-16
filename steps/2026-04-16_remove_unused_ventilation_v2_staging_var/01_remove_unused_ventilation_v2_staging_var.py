from pathlib import Path

path = Path("FB_Ventilation_System_Manager.st")
text = path.read_text(encoding="utf-8")

old = "    fbVentilationV2Staging : FB_Ventilation_V2_Staging;\n"
if old not in text:
    raise SystemExit("Unused fbVentilationV2Staging declaration not found")

text = text.replace(old, "", 1)
path.write_text(text, encoding="utf-8")
print("OK: removed unused fbVentilationV2Staging declaration")
