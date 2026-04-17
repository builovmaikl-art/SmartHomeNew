from pathlib import Path
import subprocess
import re

EXCLUDE_FILES = {
    "MAIN.st",
    "PRG_PLC_A.st",
    "PRG_PLC_B.st",
}

EXCLUDED_PREFIXES = (
    "snapshots/",
    "workspace/",
    "repo_logs/",
    "steps/",
)

def git_ls():
    out = subprocess.check_output(
        ["git", "ls-files", "*.st", "*.dut", "*.gvl", "**/*.st", "**/*.dut", "**/*.gvl"],
        text=True
    )
    return [line.strip() for line in out.splitlines() if line.strip()]

def is_live_file(path_str: str) -> bool:
    if path_str.startswith(EXCLUDED_PREFIXES):
        return False
    return Path(path_str).suffix in {".st", ".dut", ".gvl"}

def is_root_file(path_str: str) -> bool:
    return Path(path_str).parent == Path(".")

def read_text(path_str: str) -> str:
    try:
        return Path(path_str).read_text(encoding="utf-8")
    except Exception:
        return ""

all_git_files = git_ls()
live_files = [p for p in all_git_files if is_live_file(p)]
texts = {p: read_text(p) for p in live_files}

root_files = sorted(
    p for p in live_files
    if is_root_file(p) and Path(p).name not in EXCLUDE_FILES
)

def find_refs(symbol: str, exclude_file: str):
    pat = re.compile(r"\b" + re.escape(symbol) + r"\b")
    refs = []
    for path_str, text in texts.items():
        if path_str == exclude_file:
            continue
        if pat.search(text):
            refs.append(path_str)
    return refs

def classify(name: str):
    if name.startswith("FB_"):
        return "FUNCTION_BLOCK"
    if name.startswith("GVL_"):
        return "GLOBAL_VAR_LIST"
    if name.startswith("PRG_"):
        return "PROGRAM"
    if name.startswith("E_") or name.startswith("ST_"):
        return "DUT_OR_ENUM"
    return "OTHER"

inventory = []
for path_str in root_files:
    p = Path(path_str)
    symbol = p.stem
    refs = find_refs(symbol, exclude_file=path_str)
    inventory.append((p.name, p.suffix, classify(p.name), len(refs), refs))

zero_ref = [x for x in inventory if x[3] == 0]
one_ref = [x for x in inventory if x[3] == 1]

print("=== STEP 139: POST-CLEANUP ROOT AUDIT REMAINING CANDIDATES ===")
print()

print("=== EXCLUDED / PROTECTED FILES ===")
for x in sorted(EXCLUDE_FILES):
    print(x)
print()

print("=== ZERO-REF REMAINING ===")
if zero_ref:
    for name, suffix, cls, ref_count, refs in zero_ref:
        print(f"{name} | type={suffix} | class={cls}")
else:
    print("NONE")
print()

print("=== ONE-REF REMAINING ===")
if one_ref:
    for name, suffix, cls, ref_count, refs in one_ref:
        print(f"{name} | type={suffix} | class={cls}")
        for r in refs:
            print(f"  {r}")
else:
    print("NONE")
print()

print("=== GROUPED ZERO-REF ===")
groups = {}
for name, suffix, cls, ref_count, refs in zero_ref:
    groups.setdefault(cls, []).append(name)

for cls in sorted(groups):
    print(f"--- {cls} ---")
    for name in groups[cls]:
        print(name)
    print()

print("=== SUMMARY COUNTS ===")
print(f"root_files_considered={len(root_files)}")
print(f"zero_ref_count={len(zero_ref)}")
print(f"one_ref_count={len(one_ref)}")
print()

print("=== END STEP 139 ===")
