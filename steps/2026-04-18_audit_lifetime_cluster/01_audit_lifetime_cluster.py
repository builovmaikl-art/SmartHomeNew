from pathlib import Path
import subprocess
import re

CANDIDATES = [
    "E_Lifetime_Device_Type.dut",
    "ST_Lifetime_Status.dut",
]

LIVE_ANALOG_HINTS = [
    "FB_System_Health.st",
    "FB_Fault_Logger.st",
    "FB_State_Manager.st",
    "FB_Safety_Manager.st",
    "GVL_STATE.gvl",
    "GVL_STATUS.gvl",
    "GVL_CONFIG.gvl",
    "GVL_Retain.gvl",
]

EXCLUDED_PREFIXES = (
    "snapshots/",
    "workspace/",
    "repo_logs/",
    "steps/",
    "diagnostics/",
    "компилятор/",
    ".git/",
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

def preview_lines(text: str, n=40):
    return text.splitlines()[:n]

def extract_tokens(text: str):
    raw = re.findall(r"\b[A-Za-z_][A-Za-z0-9_]*\b", text)
    skip = {
        "FUNCTION_BLOCK","TYPE","STRUCT","END_STRUCT","END_TYPE",
        "VAR","VAR_INPUT","VAR_OUTPUT","VAR_IN_OUT","END_VAR",
        "IF","THEN","ELSE","ELSIF","END_IF","CASE","OF","END_CASE",
        "FOR","TO","DO","END_FOR","RETURN",
        "BOOL","BYTE","WORD","DWORD","UDINT","UINT","INT","REAL","STRING","ARRAY",
        "TRUE","FALSE",
        "attribute","strict","pack_mode",
    }
    return sorted({t for t in raw if t not in skip and len(t) >= 4})

print("=== STEP 182: AUDIT LIFETIME CLUSTER ===")
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
    print()

    text = read_text(filename)
    print(f"line_count={len(text.splitlines())}")
    print("content_preview:")
    for line in preview_lines(text, 40):
        print(line)
    print()

    candidate_tokens = extract_tokens(text)
    print(f"candidate_token_count={len(candidate_tokens)}")
    print("candidate_tokens:")
    print(", ".join(candidate_tokens))
    print()

    print("possible_live_analogs:")
    for analog in LIVE_ANALOG_HINTS:
        analog_text = texts.get(analog, "")
        analog_tokens = set(extract_tokens(analog_text))
        overlap = sorted(set(candidate_tokens) & analog_tokens)
        print(f"  {analog}: overlap_score={len(overlap)}")
        if overlap:
            print(f"    overlap_tokens={', '.join(overlap[:25])}")
    print()

print("=== END STEP 182 ===")
