from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

targets = [
    "L_Scenario_Changed      : BOOL;\n",
    "L_Last_Scenario_Change_Time : UDINT;\n",
]

for t in targets:
    if t not in text:
        raise SystemExit(f"Target VAR line not found: {t.strip()}")
    text = text.replace(t, "", 1)

path.write_text(text, encoding="utf-8")
print("OK: removed dead scenario VAR tail from PRG_System.st")
