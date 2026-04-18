from pathlib import Path
import re

root = Path(".")

ignore = {"MAIN.st", "PRG_PLC_A.st", "PRG_PLC_B.st"}

# root programs (entry points)
ROOT_PROGRAMS = {
    "PRG_System",
    "PRG_Heating",
    "PRG_IO_Read",
    "PRG_IO_Write",
    "PRG_Lighting",
    "PRG_Safety",
    "PRG_Security",
    "PRG_Ventilation",
    "PRG_Test"
}

# ------------------------------------------------------------
# 1) Load files
# ------------------------------------------------------------
files = [p for p in root.glob("*.st") if p.name not in ignore]

def_pattern = re.compile(r"(FUNCTION_BLOCK|PROGRAM)\s+(\w+)")
call_pattern = re.compile(r"\b(FB_\w+)\b")

definitions = {}
calls = {}

for f in files:
    text = f.read_text(encoding="utf-8", errors="ignore")

    m = def_pattern.search(text)
    if m:
        definitions[m.group(2)] = f.name

    called = set(call_pattern.findall(text))

    # remove self-reference
    if m:
        called.discard(m.group(2))

    calls[m.group(2) if m else f.name] = called

# ------------------------------------------------------------
# 2) Reachability (DFS)
# ------------------------------------------------------------
reachable = set()
stack = list(ROOT_PROGRAMS)

while stack:
    current = stack.pop()
    if current in reachable:
        continue

    reachable.add(current)

    for nxt in calls.get(current, []):
        if nxt not in reachable:
            stack.append(nxt)

# ------------------------------------------------------------
# 3) Classification
# ------------------------------------------------------------
reachable_defs = []
unreachable_defs = []

for name, fname in definitions.items():
    if name in reachable:
        reachable_defs.append((name, fname))
    else:
        unreachable_defs.append((name, fname))

# ------------------------------------------------------------
# 4) Print
# ------------------------------------------------------------
print("=== ROOT PROGRAMS ===")
for r in ROOT_PROGRAMS:
    print(r)

print("\n=== REACHABLE DEFINITIONS ===")
for name, fname in sorted(reachable_defs):
    print(f"{name} ({fname})")

print("\n=== UNREACHABLE DEFINITIONS (REAL ORPHANS) ===")
for name, fname in sorted(unreachable_defs):
    print(f"{name} ({fname})")

print("\n=== SUMMARY ===")
print(f"reachable={len(reachable_defs)}")
print(f"unreachable={len(unreachable_defs)}")
