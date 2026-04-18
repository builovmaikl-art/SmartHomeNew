import sys
import subprocess
from pathlib import Path

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

# 2. Forbidden / dangerous patterns in PRG_System
errors = []

prg_system = Path("PRG_System.st")
if not prg_system.exists():
    print("ERROR: PRG_System.st missing")
    sys.exit(1)

text = prg_system.read_text(encoding="utf-8")

# no direct analyzer call in PRG_System
if "L_Trend_Analyzer(" in text:
    errors.append("Direct Trend Analyzer call forbidden in PRG_System (use adapter)")

# no stale invalid field
if "HMI_Last_Message" in text:
    errors.append("Forbidden stale field HMI_Last_Message detected in PRG_System")

# duplicate vars
vars_to_check = [
    "L_Trend_Avg : REAL;",
    "L_Trend_Min : REAL;",
    "L_Trend_Max : REAL;",
    "L_Trend_Up : BOOL;",
    "L_Trend_Down : BOOL;",
]

for v in vars_to_check:
    count = text.count(v)
    if count > 1:
        errors.append(f"Duplicate variable declaration: {v} count={count}")

if errors:
    print("GUARD ERRORS:")
    for e in errors:
        print(" -", e)
    sys.exit(1)

print("OK: pattern checks passed")

# 3. Compile smoke via canonical compiler entrypoint
print("Running compile smoke...")
result = subprocess.run(
    ["python3", "компилятор/import_codesys_FINAL.py"],
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
    text=True,
)

print("=== COMPILE OUTPUT START ===")
print(result.stdout)
print("=== COMPILE OUTPUT END ===")

if result.returncode != 0:
    print(f"ERROR: compile failed with code {result.returncode}")
    sys.exit(1)

print("OK: compile passed")
print("=== REPO GUARD OK ===")
