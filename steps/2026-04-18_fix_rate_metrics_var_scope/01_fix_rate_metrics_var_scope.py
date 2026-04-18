from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

# 1) Add L_Window_Hours to main VAR section
anchor = "L_Smoke_Detected : BOOL;"
if anchor not in text:
    raise SystemExit("Main VAR anchor not found in PRG_System.st")

if "L_Window_Hours : REAL;" not in text:
    text = text.replace(
        anchor,
        anchor + "\nL_Window_Hours : REAL;",
        1
    )

# 2) Remove illegal local VAR block from executable section
bad = """// === SHADOW POLICY RATE METRICS ===
VAR
    L_Window_Hours : REAL;
END_VAR

IF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Recent_Window_MS > 0 THEN"""

good = """// === SHADOW POLICY RATE METRICS ===
IF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Recent_Window_MS > 0 THEN"""

if bad not in text:
    raise SystemExit("Illegal local VAR block not found in PRG_System.st")

text = text.replace(bad, good, 1)

path.write_text(text, encoding="utf-8")
print("OK: moved L_Window_Hours into main VAR and removed local VAR block")
