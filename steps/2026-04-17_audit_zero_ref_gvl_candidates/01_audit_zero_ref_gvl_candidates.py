from pathlib import Path
import subprocess
import re

CANDIDATES = [
    "GVL_BlackBox.gvl",
    "GVL_MODBUS.gvl",
    "GVL_TIME.gvl",
]

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

def read_text(path_str: str) -> str:
    try:
        return Path(path_str).read_text(encoding="utf-8")
    except Exception:
        return ""

all_git_files = git_ls()
live_files = [p for p in all_git_files if is_live_file(p)]
texts = {p: read_text(p) for p in live_files}

def find_refs(symbol: str, exclude_file: str):
    pat = re.compile(r"\b" + re.escape(symbol) + r"\b")
    refs = []
    for path_str, text in texts.items():
        if path_str == exclude_file:
            continue
        if pat.search(text):
            refs.append(path_str)
    return refs

print("=== STEP 137: AUDIT ZERO-REF GVL CANDIDATES ===")
print()

safe = []
hold = []

for filename in CANDIDATES:
    path = Path(filename)
    print(f"--- {filename} ---")

    if not path.exists():
        print("exists=False -> SKIP")
        print()
        continue

    symbol = path.stem
    refs = find_refs(symbol, exclude_file=filename)

    print(f"live_external_refs={len(refs)}")
    for r in refs:
        print(f"  ref={r}")

    text = read_text(filename)
    lines = text.splitlines()

    print("line_count=", len(lines))

    has_retain = any("RETAIN" in l or "PERSISTENT" in l for l in lines)
    has_io = any("AT %" in l for l in lines)
    has_constants = any("CONSTANT" in l for l in lines)
    has_system_like = any(
        x in text for x in [
            "MODBUS",
            "TIME",
            "RTC",
            "CLOCK",
            "NTP",
            "BLACKBOX",
        ]
    )

    print(f"flags: retain={has_retain}, io_mapping={has_io}, constants={has_constants}, system_like={has_system_like}")

    print("--- CONTENT PREVIEW ---")
    for l in lines[:25]:
        print(l)
    if len(lines) > 25:
        print("...")

    if len(refs) == 0 and not has_retain and not has_io:
        safe.append(filename)
        print("candidate_status=SAFE_DELETE_CANDIDATE")
    else:
        hold.append(filename)
        print("candidate_status=HOLD")

    print()

print("=== SAFE DELETE CANDIDATES ===")
for x in safe:
    print(x)
if not safe:
    print("NONE")
print()

print("=== HOLD ===")
for x in hold:
    print(x)
if not hold:
    print("NONE")
print()

print("=== END STEP 137 ===")
