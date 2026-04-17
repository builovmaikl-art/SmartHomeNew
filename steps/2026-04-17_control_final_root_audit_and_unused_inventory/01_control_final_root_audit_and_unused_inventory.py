from pathlib import Path
import subprocess
import re

ROOT = Path(".")

def git_ls(patterns):
    out = subprocess.check_output(["git", "ls-files", *patterns], text=True)
    return [Path(line.strip()) for line in out.splitlines() if line.strip()]

def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except Exception:
        return ""

all_code_files = git_ls(["*.st", "*.dut", "*.gvl"])
all_paths = [str(p) for p in all_code_files]
all_text = {str(p): read_text(p) for p in all_code_files}

owner_files = [
    Path("FB_Alarm_Manager.st"),
    Path("FB_Rule_Engine.st"),
    Path("FB_Socket_Manager.st"),
    Path("FB_DHW_Manager.st"),
    Path("FB_Ventilation_System_Manager.st"),
    Path("FB_Lighting_Blinds_Manager.st"),
    Path("FB_Heating_System_Manager.st"),
]

removed_symbols = [
    "FB_Lighting_V2_Staging",
    "FB_Heating_V2_Staging",
    "FB_Ventilation_V2_Staging",
    "FB_Blinds_V2_Staging",
    "FB_DHW_V2_Staging",
    "FB_Socket_V2_Staging",
    "FB_Alarm_Compatibility_Package",
    "FB_History_V2_Core",
    "FB_BlackBox_V2_Core",
    "FB_Alarm_V2_Core",
    "FB_Rule_Compatibility_Package",
]

internal_scaffold_pattern = re.compile(
    r"L_.*(_V2_|_Path_Ready|_Using_Legacy_Fallback|_Shadow_Diff_Found|_Switch_Enabled)"
)

cosmetic_comment_pattern = re.compile(
    r"Inlined from|phase2|phase3|V2 shadow|staging layer|compatibility path is"
)

def find_refs(symbol: str, exclude_file: str | None = None):
    refs = []
    pat = re.compile(r"\b" + re.escape(symbol) + r"\b")
    for path_str, text in all_text.items():
        if exclude_file and path_str == exclude_file:
            continue
        if pat.search(text):
            refs.append(path_str)
    return refs

def count_refs(symbol: str, exclude_file: str | None = None):
    return len(find_refs(symbol, exclude_file=exclude_file))

root_files = [p for p in all_code_files if p.parent == ROOT and p.suffix in {".st", ".dut", ".gvl"}]

print("=== STEP 131: CONTROL FINAL ROOT AUDIT AND UNUSED INVENTORY ===")
print()

print("=== SECTION A: CLEANUP WAVE CONTROL CHECK ===")
print("-- owner files --")
for p in owner_files:
    print(p.name)
print()

print("-- internal scaffold residuals in owner files --")
owner_residuals = []
for p in owner_files:
    text = all_text.get(str(p), "")
    for i, line in enumerate(text.splitlines(), start=1):
        if internal_scaffold_pattern.search(line):
            owner_residuals.append((p.name, i, line))
if owner_residuals:
    for item in owner_residuals:
        print(f"{item[0]}:{item[1]}:{item[2]}")
else:
    print("NONE")
print()

print("-- stale cleanup comments in owner files --")
owner_comment_residuals = []
for p in owner_files:
    text = all_text.get(str(p), "")
    for i, line in enumerate(text.splitlines(), start=1):
        if cosmetic_comment_pattern.search(line):
            owner_comment_residuals.append((p.name, i, line))
if owner_comment_residuals:
    for item in owner_comment_residuals:
        print(f"{item[0]}:{item[1]}:{item[2]}")
else:
    print("NONE")
print()

print("-- references to removed cleanup symbols --")
for sym in removed_symbols:
    refs = find_refs(sym)
    print(f"{sym}: {len(refs)}")
    for ref in refs:
        print(f"  {ref}")
print()

print("=== SECTION B: ROOT INVENTORY OF POSSIBLY UNUSED FILES ===")
print("-- root files considered --")
for p in sorted(root_files):
    print(p.name)
print()

print("-- per-file symbol reference inventory (excluding self-file) --")
inventory = []
for p in sorted(root_files):
    symbol = p.stem
    refs = find_refs(symbol, exclude_file=str(p))
    inventory.append((p.name, p.suffix, symbol, len(refs), refs))

for name, suffix, symbol, ref_count, refs in inventory:
    print(f"{name} | type={suffix} | symbol={symbol} | external_refs={ref_count}")
    for ref in refs[:20]:
        print(f"  {ref}")
    if len(refs) > 20:
        print(f"  ... +{len(refs)-20} more")
print()

print("-- strong candidates: zero external refs --")
zero_ref = [x for x in inventory if x[3] == 0]
if zero_ref:
    for name, suffix, symbol, ref_count, refs in zero_ref:
        print(f"{name} | type={suffix} | symbol={symbol}")
else:
    print("NONE")
print()

print("-- note --")
print("Zero external refs is only a candidate signal.")
print("Files may still be entrypoints, reflection-bound, compiler-discovered, or referenced indirectly.")
print("Need manual review before delete.")
print()

print("=== END STEP 131 ===")
