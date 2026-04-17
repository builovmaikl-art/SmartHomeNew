from pathlib import Path
import subprocess
import re

CANDIDATES = [
    "FB_DryRun_Assertion_Map.st",
    "FB_DryRun_Simulation_Harness.st",
    "FB_Trend_Analyzer.st",
    "FB_Trend_Logger.st",
    "FB_State_Snapshot_Manager.st",
    "FB_State_Snapshot_NVRAM.st",
    "ST_Debug_Log_Record.dut",
    "ST_Debug_Logger_Config.dut",
    "ST_State_Snapshot.dut",
    "ST_Trend_Config.dut",
    "ST_Trend_Data.dut",
    "ST_Trend_Header.dut",
    "ST_Trend_History_Record.dut",
    "E_Debug_Log_Level.dut",
    "E_Trend_Parameter_Type.dut",
]

LIVE_ANALOG_HINTS = [
    "FB_History_Manager.st",
    "FB_BlackBox_Recorder.st",
    "FB_NVRAM_Manager.st",
    "ST_History_Record.dut",
    "ST_System_State_Snapshot.dut",
    "GVL_Retain.gvl",
]

EXCLUDED_PREFIXES = (
    "snapshots/",
    "workspace/",
    "repo_logs/",
    "steps/",
    "diagnostics/",
    "компилятор/",
)

def git_ls():
    out = subprocess.check_output(
        ["git", "ls-files", "*.st", "*.dut", "*.gvl", "**/*.st", "**/*.dut", "**/*.gvl"],
        text=True
    )
    return [line.strip() for line in out.splitlines() if line.strip()]

def is_live_file(path_str: str) -> bool:
    return not path_str.startswith(EXCLUDED_PREFIXES)

def read_text(path_str: str) -> str:
    try:
        return Path(path_str).read_text(encoding="utf-8")
    except Exception:
        return ""

all_git_files = git_ls()
live_files = [p for p in all_git_files if is_live_file(p)]
texts = {p: read_text(p) for p in live_files}

def find_refs(symbol: str, exclude_file: str | None = None):
    pat = re.compile(r"\b" + re.escape(symbol) + r"\b")
    refs = []
    for path_str, text in texts.items():
        if exclude_file and path_str == exclude_file:
            continue
        if pat.search(text):
            refs.append(path_str)
    return sorted(refs)

def preview_lines(text: str, n=25):
    lines = text.splitlines()
    return lines[:n]

print("=== STEP 146: AUDIT UNREACHABLE CLUSTER FUNCTIONAL GAP ===")
print()

for filename in CANDIDATES:
    path = Path(filename)
    print(f"--- {filename} ---")
    print(f"exists={path.exists()}")
    if not path.exists():
        print("status=MISSING")
        print()
        continue

    symbol = path.stem
    refs = find_refs(symbol, exclude_file=filename)
    print(f"live_refs={len(refs)}")
    for r in refs[:20]:
        print(f"  ref={r}")
    if len(refs) > 20:
        print(f"  ... +{len(refs)-20} more")

    text = read_text(filename)
    print(f"line_count={len(text.splitlines())}")

    print("content_preview:")
    for line in preview_lines(text, 25):
        print(line)
    if len(text.splitlines()) > 25:
        print("...")

    print("possible_live_analogs:")
    for analog in LIVE_ANALOG_HINTS:
        analog_text = texts.get(analog, "")
        hits = []
        for token in re.findall(r"\b[A-Za-z_][A-Za-z0-9_]*\b", text):
            if token in analog_text and token not in {"TYPE","STRUCT","END_STRUCT","END_TYPE","FUNCTION_BLOCK","VAR","VAR_INPUT","VAR_OUTPUT","BOOL","INT","REAL","BYTE","WORD","DWORD","UDINT","STRING","ARRAY","OF"}:
                hits.append(token)
        uniq_hits = sorted(set(hits))
        score = len(uniq_hits)
        print(f"  {analog}: overlap_score={score}")
        if uniq_hits:
            print(f"    overlap_tokens={', '.join(uniq_hits[:20])}")

    print()

print("=== END STEP 146 ===")
