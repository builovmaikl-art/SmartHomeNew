from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

old = "    L_Trend_Analyzer : FB_Trend_Analyzer;\n"

if old not in text:
    raise SystemExit("No leftover L_Trend_Analyzer declaration found in PRG_System.st")

text = text.replace(old, "", 1)
path.write_text(text, encoding="utf-8")
print("OK: removed unused L_Trend_Analyzer declaration from PRG_System.st")
