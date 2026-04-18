from pathlib import Path
import re

root = Path(".")

# ------------------------------------------------------------
# 1) Collect all .st files in root
# ------------------------------------------------------------
st_files = [p for p in root.glob("*.st")]

ignore = {"MAIN.st", "PRG_PLC_A.st", "PRG_PLC_B.st"}

st_files = [p for p in st_files if p.name not in ignore]

# ------------------------------------------------------------
# 2) Detect FB/PRG names
# ------------------------------------------------------------
definitions = {}
calls = {}

def_name_pattern = re.compile(r"(FUNCTION_BLOCK|PROGRAM)\s+(\w+)")
call_pattern = re.compile(r"\b(FB_\w+)\b")

for f in st_files:
    text = f.read_text(encoding="utf-8", errors="ignore")

    # definitions
    m = def_name_pattern.search(text)
    if m:
        definitions[m.group(2)] = f.name

    # calls
    found = set(call_pattern.findall(text))
    calls[f.name] = found

# ------------------------------------------------------------
# 3) Reverse map (who is used)
# ------------------------------------------------------------
used = set()
for cset in calls.values():
    used |= cset

# ------------------------------------------------------------
# 4) Classification
# ------------------------------------------------------------
used_defs = []
unused_defs = []

for name, fname in definitions.items():
    if name in used:
        used_defs.append((name, fname))
    else:
        unused_defs.append((name, fname))

# ------------------------------------------------------------
# 5) Print report
# ------------------------------------------------------------
print("=== ROOT ST FILES ===")
for f in st_files:
    print(f.name)

print("\n=== DEFINITIONS ===")
for name, fname in definitions.items():
    print(f"{name} -> {fname}")

print("\n=== CALL GRAPH (partial) ===")
for fname, cset in calls.items():
    if cset:
        print(f"{fname} calls: {', '.join(sorted(cset))}")

print("\n=== USED DEFINITIONS ===")
for name, fname in sorted(used_defs):
    print(f"{name} ({fname})")

print("\n=== UNUSED DEFINITIONS (CANDIDATES) ===")
for name, fname in sorted(unused_defs):
    print(f"{name} ({fname})")

print("\n=== SUMMARY ===")
print(f"total_files={len(st_files)}")
print(f"definitions={len(definitions)}")
print(f"used={len(used_defs)}")
print(f"unused={len(unused_defs)}")
