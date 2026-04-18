from pathlib import Path
import subprocess
import re
from collections import defaultdict

EXCLUDED_PREFIXES = (
    "snapshots/",
    "workspace/",
    "repo_logs/",
    "steps/",
    "diagnostics/",
    "компилятор/",
    ".git/",
    "archive/",
)

LIVE_ANALOG_HINTS = [
    "PRG_System.st",
    "PRG_Heating.st",
    "PRG_Ventilation.st",
    "FB_Safety_Manager.st",
    "FB_System_Health.st",
    "FB_Alarm_Manager.st",
    "ST_Zone_Sensors.dut",
    "GVL_STATE.gvl",
    "GVL_STATUS.gvl",
    "GVL_CONFIG.gvl",
]

KEYWORDS = [
    "sensor",
    "detector",
    "gas_",
    "smoke_",
    "co_",
    "maintenance",
]

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

def extract_tokens(text: str):
    raw = re.findall(r"\b[A-Za-z_][A-Za-z0-9_]*\b", text)
    skip = {
        "FUNCTION_BLOCK","TYPE","STRUCT","END_STRUCT","END_TYPE",
        "VAR","VAR_INPUT","VAR_OUTPUT","VAR_IN_OUT","END_VAR",
        "IF","THEN","ELSE","ELSIF","END_IF","CASE","OF","END_CASE",
        "FOR","TO","DO","END_FOR","WHILE","END_WHILE","RETURN",
        "BOOL","BYTE","WORD","DWORD","UDINT","UINT","INT","REAL","LREAL","STRING","ARRAY",
        "TRUE","FALSE",
        "attribute","strict","pack_mode",
    }
    return sorted({t for t in raw if t not in skip and len(t) >= 4})

def classify(path_str: str) -> str:
    name = Path(path_str).name
    if name.startswith("FB_"):
        return "FUNCTION_BLOCK"
    if name.startswith("ST_") or name.startswith("E_"):
        return "DUT_OR_ENUM"
    if name.startswith("GVL_"):
        return "GLOBAL_VAR_LIST"
    if name.startswith("PRG_") or name == "MAIN.st":
        return "PROGRAM"
    return "OTHER"

all_files = [p for p in git_ls() if is_live_file(p)]
texts = {p: read_text(p) for p in all_files}

candidates = []
for p in sorted(all_files):
    low = Path(p).name.lower()
    if any(k in low for k in KEYWORDS):
        candidates.append(p)

# de-noise: keep root live code only
candidates = [p for p in candidates if Path(p).parent == Path(".")]

def find_refs(symbol: str, exclude_file: str | None = None):
    pat = re.compile(r"\b" + re.escape(symbol) + r"\b")
    refs = []
    for path_str, text in texts.items():
        if exclude_file and path_str == exclude_file:
            continue
        if pat.search(text):
            refs.append(path_str)
    return sorted(refs)

print("=== STEP 195: AUDIT SENSORS_SAFETY_LEAVES ===")
print()

print("=== CANDIDATE SET ===")
for p in candidates:
    print(f"{p} | class={classify(p)}")
print()

buckets = defaultdict(list)
for p in candidates:
    low = Path(p).name.lower()
    if "gas_" in low or "_gas" in low:
        buckets["GAS"].append(p)
    elif "smoke_" in low or "_smoke" in low:
        buckets["SMOKE"].append(p)
    elif "co_" in low or "_co" in low:
        buckets["CO"].append(p)
    elif "maintenance" in low:
        buckets["MAINTENANCE"].append(p)
    elif "detector" in low:
        buckets["DETECTORS"].append(p)
    else:
        buckets["SENSORS_OTHER"].append(p)

for bucket in sorted(buckets):
    print(f"=== BUCKET {bucket} ===")
    for filename in sorted(buckets[bucket]):
        path = Path(filename)
        symbol = path.stem
        text = texts.get(filename, "")
        refs = find_refs(symbol, exclude_file=filename)
        print(f"--- {filename} ---")
        print(f"live_refs={len(refs)}")
        for r in refs[:20]:
            print(f"  ref={r}")
        if len(refs) > 20:
            print(f"  ... +{len(refs)-20} more")
        print(f"line_count={len(text.splitlines())}")
        print("preview:")
        for line in text.splitlines()[:30]:
            print(line)
        if len(text.splitlines()) > 30:
            print("...")
        print("possible_live_analogs:")
        candidate_tokens = set(extract_tokens(text))
        for analog in LIVE_ANALOG_HINTS:
            analog_tokens = set(extract_tokens(texts.get(analog, "")))
            overlap = sorted(candidate_tokens & analog_tokens)
            print(f"  {analog}: overlap_score={len(overlap)}")
            if overlap:
                print(f"    overlap_tokens={', '.join(overlap[:25])}")
        print()

print("=== SPECIAL FOCUS: ST_Zone_Sensors ===")
zone_text = texts.get("ST_Zone_Sensors.dut", "")
print(f"exists={bool(zone_text)}")
for line in zone_text.splitlines()[:120]:
    print(line)
print()

print("=== SPECIAL FOCUS: GVL_STATE SAFETY SIGNALS ===")
for i, line in enumerate(texts.get("GVL_STATE.gvl", "").splitlines(), start=1):
    low = line.lower()
    if "smoke" in low or "gas" in low or "co" in low or "sensor" in low or "detector" in low:
        print(f"{i}:{line}")
print()

print("=== END STEP 195 ===")
