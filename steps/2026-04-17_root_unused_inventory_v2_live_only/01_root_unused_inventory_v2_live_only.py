from pathlib import Path
import subprocess
import re

ROOT = Path(".")

EXCLUDED_PREFIXES = (
    "snapshots/",
    "workspace/",
    "repo_logs/",
    "steps/",
)

def git_ls(patterns):
    out = subprocess.check_output(["git", "ls-files", *patterns], text=True)
    return [line.strip() for line in out.splitlines() if line.strip()]

def is_live_root_file(path_str: str) -> bool:
    p = Path(path_str)
    if p.parent != Path("."):
        return False
    return p.suffix in {".st", ".dut", ".gvl"}

def is_live_search_file(path_str: str) -> bool:
    if path_str.startswith(EXCLUDED_PREFIXES):
        return False
    p = Path(path_str)
    return p.suffix in {".st", ".dut", ".gvl"}

def read_text(path_str: str) -> str:
    try:
        return Path(path_str).read_text(encoding="utf-8")
    except Exception:
        return ""

all_git_files = git_ls(["*.st", "*.dut", "*.gvl", "**/*.st", "**/*.dut", "**/*.gvl"])

live_root_files = sorted([p for p in all_git_files if is_live_root_file(p)])
live_search_files = sorted([p for p in all_git_files if is_live_search_file(p)])

texts = {p: read_text(p) for p in live_search_files}

def find_refs(symbol: str, exclude_file: str):
    pat = re.compile(r"\b" + re.escape(symbol) + r"\b")
    refs = []
    for path_str, text in texts.items():
        if path_str == exclude_file:
            continue
        if pat.search(text):
            refs.append(path_str)
    return refs

inventory = []
for path_str in live_root_files:
    p = Path(path_str)
    symbol = p.stem
    refs = find_refs(symbol, exclude_file=path_str)
    inventory.append((p.name, p.suffix, symbol, len(refs), refs))

zero_ref = [x for x in inventory if x[3] == 0]
one_ref = [x for x in inventory if x[3] == 1]

print("=== STEP 132: ROOT UNUSED INVENTORY V2 (LIVE ONLY) ===")
print()

print("=== EXCLUDED PREFIXES ===")
for x in EXCLUDED_PREFIXES:
    print(x)
print()

print("=== LIVE ROOT FILES ===")
for x in live_root_files:
    print(Path(x).name)
print()

print("=== PER-FILE INVENTORY ===")
for name, suffix, symbol, ref_count, refs in inventory:
    print(f"{name} | type={suffix} | symbol={symbol} | external_refs={ref_count}")
    for ref in refs[:20]:
        print(f"  {ref}")
    if len(refs) > 20:
        print(f"  ... +{len(refs)-20} more")
print()

print("=== STRONG CANDIDATES: ZERO EXTERNAL REFS ===")
if zero_ref:
    for name, suffix, symbol, ref_count, refs in zero_ref:
        print(f"{name} | type={suffix} | symbol={symbol}")
else:
    print("NONE")
print()

print("=== WEAK CANDIDATES: ONE EXTERNAL REF ===")
if one_ref:
    for name, suffix, symbol, ref_count, refs in one_ref:
        print(f"{name} | type={suffix} | symbol={symbol}")
        for ref in refs:
            print(f"  {ref}")
else:
    print("NONE")
print()

print("=== NOTE ===")
print("This is a live-root-only candidate map.")
print("Zero/one external refs still do not prove deletability.")
print("Entrypoints, compiler-discovered objects, retained globals, interfaces, and manually-instantiated programs need review.")
print()

print("=== END STEP 132 ===")
