from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

anchor = """L_Methane_Calibrated : REAL;
L_Smoke_Detected : BOOL;
"""

replacement = """L_Methane_Calibrated : REAL;
L_Smoke_Detected : BOOL;
L_Window_Hours : REAL;
"""

if "L_Window_Hours : REAL;" in text:
    print("OK: L_Window_Hours already declared")
else:
    if anchor not in text:
        raise SystemExit("Exact VAR anchor not found in PRG_System.st")
    text = text.replace(anchor, replacement, 1)
    path.write_text(text, encoding="utf-8")
    print("OK: added L_Window_Hours : REAL; to PRG_System VAR section")
