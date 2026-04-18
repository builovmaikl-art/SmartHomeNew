from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

marker = "// === SAFETY SELECTOR LAYER ==="
if marker not in text:
    raise SystemExit("SAFETY SELECTOR LAYER marker not found in PRG_System.st")

line = "GVL_Safety_Selector.G_Use_Shadow_CO := TRUE;"

if line not in text:
    text = text.replace(
        marker,
        marker + "\n" + line,
        1
    )

path.write_text(text, encoding="utf-8")
print("OK: enabled GVL_Safety_Selector.G_Use_Shadow_CO := TRUE")
