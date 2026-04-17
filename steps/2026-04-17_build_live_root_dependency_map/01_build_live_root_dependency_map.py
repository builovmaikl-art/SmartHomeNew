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
)

PROTECTED_ROOTS = {
    "MAIN.st",
    "PRG_PLC_A.st",
    "PRG_PLC_B.st",
}

def git_ls():
    out = subprocess.check_output(
        ["git", "ls-files", "*.st", "*.dut", "*.gvl", "**/*.st", "**/*.dut", "**/*.gvl"],
        text=True
    )
    return [line.strip() for line in out.splitlines() if line.strip()]

def is_live_file(path_str: str) -> bool:
    return not path_str.startswith(EXCLUDED_PREFIXES)

def is_root_code_file(path_str: str) -> bool:
    p = Path(path_str)
    return p.parent == Path(".") and p.suffix in {".st", ".dut", ".gvl"}

def classify(name: str) -> str:
    if name == "MAIN.st":
        return "MAIN"
    if name.startswith("PRG_"):
        return "PROGRAM"
    if name.startswith("FB_"):
        return "FUNCTION_BLOCK"
    if name.startswith("GVL_"):
        return "GLOBAL_VAR_LIST"
    if name.startswith("ST_") or name.startswith("E_"):
        return "DUT_OR_ENUM"
    return "OTHER"

def read_text(path_str: str) -> str:
    try:
        return Path(path_str).read_text(encoding="utf-8")
    except Exception:
        return ""

all_git_files = git_ls()
live_files = [p for p in all_git_files if is_live_file(p)]
root_files = sorted([p for p in live_files if is_root_code_file(p)])

texts = {p: read_text(p) for p in live_files}
symbols = {Path(p).stem: p for p in root_files}

# adjacency: source file -> referenced root files
adj = defaultdict(set)
rev = defaultdict(set)

for src in root_files:
    text = texts[src]
    for sym, target in symbols.items():
        if target == src:
            continue
        if re.search(r"\b" + re.escape(sym) + r"\b", text):
            adj[src].add(target)
            rev[target].add(src)

# sort
adj = {k: sorted(v) for k, v in sorted(adj.items())}
rev = {k: sorted(v) for k, v in sorted(rev.items())}

all_root_set = set(root_files)

zero_in = sorted(all_root_set - set(rev.keys()))
zero_out = sorted(all_root_set - set(adj.keys()))
program_roots = sorted([p for p in root_files if Path(p).name.startswith("PRG_") or Path(p).name == "MAIN.st"])

# category summaries
by_class = defaultdict(list)
for p in root_files:
    by_class[classify(Path(p).name)].append(p)

# write detailed markdown map
md_path = Path("workspace/dependency_map_live_root.md")
md_path.parent.mkdir(parents=True, exist_ok=True)

with md_path.open("w", encoding="utf-8") as f:
    f.write("# Live root dependency map\n\n")
    f.write("## Root files considered\n\n")
    for cls in sorted(by_class):
        f.write(f"### {cls}\n")
        for p in sorted(by_class[cls]):
            f.write(f"- {p}\n")
        f.write("\n")

    f.write("## Program roots\n\n")
    for p in program_roots:
        f.write(f"- {p}\n")
    f.write("\n")

    f.write("## Zero incoming references\n\n")
    for p in zero_in:
        f.write(f"- {p} [{classify(Path(p).name)}]\n")
    f.write("\n")

    f.write("## Zero outgoing references\n\n")
    for p in zero_out:
        f.write(f"- {p} [{classify(Path(p).name)}]\n")
    f.write("\n")

    f.write("## Forward edges\n\n")
    for src in root_files:
        f.write(f"### {src} [{classify(Path(src).name)}]\n")
        deps = adj.get(src, [])
        if deps:
            for d in deps:
                f.write(f"- {d} [{classify(Path(d).name)}]\n")
        else:
            f.write("- (none)\n")
        f.write("\n")

    f.write("## Reverse edges\n\n")
    for dst in root_files:
        f.write(f"### {dst} [{classify(Path(dst).name)}]\n")
        users = rev.get(dst, [])
        if users:
            for u in users:
                f.write(f"- {u} [{classify(Path(u).name)}]\n")
        else:
            f.write("- (none)\n")
        f.write("\n")

print("=== STEP 144: BUILD LIVE ROOT DEPENDENCY MAP ===")
print()

print("=== ROOT FILE COUNTS ===")
for cls in sorted(by_class):
    print(f"{cls}={len(by_class[cls])}")
print(f"TOTAL={len(root_files)}")
print()

print("=== PROGRAM ROOTS ===")
for p in program_roots:
    print(p)
print()

print("=== ZERO INCOMING REFERENCES ===")
for p in zero_in:
    print(f"{p} | class={classify(Path(p).name)}")
print()

print("=== ZERO OUTGOING REFERENCES ===")
for p in zero_out:
    print(f"{p} | class={classify(Path(p).name)}")
print()

print("=== HIGH-VALUE PROGRAM EDGES ===")
for p in program_roots:
    print(f"--- {p} ---")
    deps = adj.get(p, [])
    for d in deps:
        print(f"  -> {d} [{classify(Path(d).name)}]")
    if not deps:
        print("  -> (none)")
    print()

print("=== SELECTED CORE MANAGER REVERSE DEPS ===")
selected = [
    "FB_Heating_System_Manager.st",
    "FB_DHW_Manager.st",
    "FB_Lighting_Blinds_Manager.st",
    "FB_Ventilation_System_Manager.st",
    "FB_Rule_Engine.st",
    "FB_Alarm_Manager.st",
    "FB_Socket_Manager.st",
]
for s in selected:
    if s in all_root_set:
        print(f"--- {s} ---")
        users = rev.get(s, [])
        for u in users:
            print(f"  <- {u} [{classify(Path(u).name)}]")
        if not users:
            print("  <- (none)")
        print()

print("=== ARTIFACT ===")
print(md_path.as_posix())
print()

print("=== END STEP 144 ===")
