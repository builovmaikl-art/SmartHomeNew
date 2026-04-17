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

root_files = [
    p for p in live_files
    if is_root_file(p) and Path(p).name not in EXCLUDE_FILES
]

def find_refs(symbol: str, exclude_file: str):
    pat = re.compile(r"\b" + re.escape(symbol) + r"\b")
    refs = []
    for path_str, text in texts.items():
        if path_str == exclude_file:
            continue
        if pat.search(text):
            refs.append(path_str)
    return refs

zero_ref = []

for path_str in root_files:
    p = Path(path_str)
    symbol = p.stem
    refs = find_refs(symbol, exclude_file=path_str)
    if len(refs) == 0:
        zero_ref.append((p.name, p.suffix, symbol))

def classify(name: str):
    lname = name.lower()

    if any(x in lname for x in ["test", "testrig", "debug", "mvp", "mock"]):
        return "TEST_OR_DEBUG"

    if name.startswith("GVL_"):
        return "GLOBAL_VAR_LIST"

    if name.startswith("PRG_"):
        return "PROGRAM"

    if name.startswith("FB_"):
        return "FUNCTION_BLOCK"

    return "OTHER"

classified = [(name, suffix, symbol, classify(name)) for name, suffix, symbol in zero_ref]

print("=== STEP 135: CLASSIFY REMAINING ZERO-REF ROOT OBJECTS ===")
print()

print("=== ZERO-REF ROOT FILES (FILTERED) ===")
for name, suffix, symbol, cls in classified:
    print(f"{name} | type={suffix} | class={cls}")
print()

print("=== GROUPED ===")

groups = {}
for item in classified:
    groups.setdefault(item[3], []).append(item[0])

for g, items in groups.items():
    print(f"--- {g} ---")
    for x in items:
        print(x)
    print()

print("=== RECOMMENDED NEXT ACTION ===")
print("TEST_OR_DEBUG -> strong delete candidates")
print("FUNCTION_BLOCK -> manual review")
print("GLOBAL_VAR_LIST -> careful (may be implicitly used)")
print("PROGRAM -> check if unused entrypoints")
print()

print("=== END STEP 135 ===")
