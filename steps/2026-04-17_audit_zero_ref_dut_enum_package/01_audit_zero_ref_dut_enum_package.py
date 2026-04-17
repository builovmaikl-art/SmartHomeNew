from pathlib import Path
import subprocess
import re

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
    if is_root_file(p) and Path(p).suffix == ".dut"
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

zero_ref_dut = []

for path_str in root_files:
    p = Path(path_str)
    symbol = p.stem
    refs = find_refs(symbol, exclude_file=path_str)
    if len(refs) == 0:
        zero_ref_dut.append(path_str)

def classify_content(text: str):
    lines = text.splitlines()

    is_enum = "TYPE" in text and "ENUM" in text
    is_struct = "STRUCT" in text
    has_nested_types = bool(re.search(r"\bST_|E_", text))
    has_config_words = bool(re.search(r"CONFIG|STATE|STATUS|SUMMARY|RULE", text))
    has_diag_words = bool(re.search(r"DEBUG|DIAG|LOG", text))
    is_empty = len([l for l in lines if l.strip() and not l.strip().startswith("//")]) <= 3

    return {
        "is_enum": is_enum,
        "is_struct": is_struct,
        "has_nested_types": has_nested_types,
        "has_config_words": has_config_words,
        "has_diag_words": has_diag_words,
        "is_empty": is_empty,
        "line_count": len(lines),
    }

print("=== STEP 140: AUDIT ZERO-REF DUT/ENUM PACKAGE ===")
print()

safe = []
hold = []

for path_str in sorted(zero_ref_dut):
    name = Path(path_str).name
    text = read_text(path_str)

    refs = find_refs(Path(path_str).stem, exclude_file=path_str)
    info = classify_content(text)

    print(f"--- {name} ---")
    print(f"line_count={info['line_count']}")
    print(f"is_enum={info['is_enum']} is_struct={info['is_struct']}")
    print(f"nested_types={info['has_nested_types']}")
    print(f"config_like={info['has_config_words']} diag_like={info['has_diag_words']}")
    print(f"is_empty={info['is_empty']}")

    print("preview:")
    for l in text.splitlines()[:20]:
        print(l)
    if len(text.splitlines()) > 20:
        print("...")

    # decision heuristic
    if info["is_empty"]:
        decision = "SAFE_DELETE_CANDIDATE"
        safe.append(name)
    elif info["is_enum"] and not info["has_nested_types"] and not info["has_config_words"]:
        decision = "SAFE_DELETE_CANDIDATE"
        safe.append(name)
    elif not info["has_nested_types"] and not info["has_config_words"] and not info["has_diag_words"]:
        decision = "LIKELY_SAFE"
        safe.append(name)
    else:
        decision = "HOLD"
        hold.append(name)

    print(f"decision={decision}")
    print()

print("=== SAFE / LIKELY SAFE ===")
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

print("=== END STEP 140 ===")
