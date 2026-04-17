from pathlib import Path
import subprocess
import re

CANDIDATES = [
    "ST_BlackBox_Snapshot_V2.dut",
    "ST_Blinds_Command_V2.dut",
    "ST_Blinds_State_V2.dut",
    "ST_DHW_Command_V2.dut",
    "ST_DHW_State_V2.dut",
    "ST_Heating_Command_V2.dut",
    "ST_Heating_State_V2.dut",
    "ST_History_Event_V2.dut",
    "ST_Lighting_Command_V2.dut",
    "ST_Lighting_State_V2.dut",
    "ST_Socket_Command_V2.dut",
    "ST_Socket_State_V2.dut",
    "ST_Ventilation_Command_V2.dut",
    "ST_Ventilation_State_V2.dut",
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

print("=== STEP 133: AUDIT ZERO-REF V2 DUT LEFTOVERS ===")
print()

safe_delete = []
needs_hold = []

for filename in CANDIDATES:
    path = Path(filename)
    symbol = path.stem
    exists = path.exists()
    print(f"--- {filename} ---")
    print(f"exists={exists}")
    if not exists:
        print("status=missing")
        print()
        continue

    refs = find_refs(symbol, exclude_file=filename)
    print(f"live_external_refs={len(refs)}")
    for ref in refs:
        print(f"  ref={ref}")

    text = read_text(filename)
    line_count = len(text.splitlines())
    print(f"line_count={line_count}")

    uses_v2_markers = bool(re.search(r"\bV2\b|_V2\b", text))
    print(f"contains_v2_markers={uses_v2_markers}")

    if len(refs) == 0:
        safe_delete.append(filename)
        print("candidate_status=SAFE_DELETE_CANDIDATE")
    else:
        needs_hold.append(filename)
        print("candidate_status=HOLD")
    print()

print("=== SAFE DELETE CANDIDATES ===")
for x in safe_delete:
    print(x)
if not safe_delete:
    print("NONE")
print()

print("=== HOLD ===")
for x in needs_hold:
    print(x)
if not needs_hold:
    print("NONE")
print()

print("=== END STEP 133 ===")
