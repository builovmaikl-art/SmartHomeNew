import sys
import subprocess
from pathlib import Path
import re

print("=== REPO GUARD START ===")

# 1. Critical files must exist
critical = [
    "PRG_System.st",
    "MAIN.st",
    "PRG_PLC_A.st",
    "PRG_PLC_B.st",
]

for f in critical:
    if not Path(f).exists():
        print(f"ERROR: missing critical file {f}")
        sys.exit(1)

print("OK: critical files present")

# 2. Forbidden patterns
errors = []

text = Path("PRG_System.st").read_text(encoding="utf-8")

# no direct analyzer call
if "L_Trend_Analyzer(" in text:
    errors.append("Direct Trend Analyzer call forbidden (use adapter)")

# no HMI_Last_Message
if "HMI_Last_Message" in text:
    errors.append("Forbidden field HMI_Last_Message detected")

# duplicate vars
vars_to_check = [
    "L_Trend_Avg : REAL;",
    "L_Trend_Min : REAL;",
    "L_Trend_Max : REAL;",
]

for v in vars_to_check:
    if text.count(v) > 1:
        errors.append(f"Duplicate variable: {v}")

if errors:
    print("GUARD ERRORS:")
    for e in errors:
        print(" -", e)
    sys.exit(1)

print("OK: pattern checks passed")

# 3. Compile smoke
print("Running compile smoke...")
result = subprocess.run(
    ["python3", "компилятор/import_codesys_FINAL.py"],
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
)

if result.returncode != 0:
    print("ERROR: compile failed")
    print(result.stdout.decode())
    sys.exit(1)

print("OK: compile passed")
print("=== REPO GUARD OK ===")
