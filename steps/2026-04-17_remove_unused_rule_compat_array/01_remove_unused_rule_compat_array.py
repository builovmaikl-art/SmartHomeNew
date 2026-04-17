from pathlib import Path

path = Path("FB_Rule_Engine.st")
text = path.read_text(encoding="utf-8")

old = "    fbCompat : ARRAY[1..GVL_CONSTANTS.C_MAX_RULES] OF FB_Rule_Compatibility_Package;\n"
if old not in text:
    raise SystemExit("Unused fbCompat declaration not found")

text = text.replace(old, "", 1)
path.write_text(text, encoding="utf-8")
print("OK: removed unused fbCompat declaration")
