from pathlib import Path
import subprocess
import re
from collections import defaultdict, deque

EXCLUDED_PREFIXES = (
    "snapshots/",
    "workspace/",
    "repo_logs/",
    "steps/",
    "diagnostics/",
    "компилятор/",
)

ENTRYPOINTS = [
    "MAIN.st",
]

PROTECTED = {
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

adj = {k: sorted(v) for k, v in adj.items()}
rev = {k: sorted(v) for k, v in rev.items()}

# BFS from entrypoints
reachable = set()
q = deque()

for ep in ENTRYPOINTS:
    if ep in root_files:
        q.append(ep)
        reachable.add(ep)

while q:
    node = q.popleft()
    for nxt in adj.get(node, []):
        if nxt not in reachable:
            reachable.add(nxt)
            q.append(nxt)

all_root = set(root_files)
unreachable = sorted(all_root - reachable)

# classified summaries
reachable_by_class = defaultdict(list)
unreachable_by_class = defaultdict(list)

for p in sorted(reachable):
    reachable_by_class[classify(Path(p).name)].append(p)

for p in unreachable:
    unreachable_by_class[classify(Path(p).name)].append(p)

# "high suspicion": unreachable and not protected
high_suspicion = [p for p in unreachable if Path(p).name not in PROTECTED]

# write artifact
md_path = Path("workspace/reachable_graph_from_main.md")
md_path.parent.mkdir(parents=True, exist_ok=True)

with md_path.open("w", encoding="utf-8") as f:
    f.write("# Reachable graph from MAIN\n\n")

    f.write("## Entrypoints\n\n")
    for ep in ENTRYPOINTS:
        f.write(f"- {ep}\n")
    f.write("\n")

    f.write("## Reachable summary\n\n")
    for cls in sorted(reachable_by_class):
        f.write(f"### {cls}\n")
        for p in sorted(reachable_by_class[cls]):
            f.write(f"- {p}\n")
        f.write("\n")

    f.write("## Unreachable summary\n\n")
    for cls in sorted(unreachable_by_class):
        f.write(f"### {cls}\n")
        for p in sorted(unreachable_by_class[cls]):
            f.write(f"- {p}\n")
        f.write("\n")

    f.write("## Forward edges for reachable nodes\n\n")
    for src in sorted(reachable):
        f.write(f"### {src} [{classify(Path(src).name)}]\n")
        deps = adj.get(src, [])
        deps = [d for d in deps if d in reachable]
        if deps:
            for d in deps:
                f.write(f"- {d} [{classify(Path(d).name)}]\n")
        else:
            f.write("- (none)\n")
        f.write("\n")

    f.write("## Unreachable candidates (excluding protected)\n\n")
    for p in high_suspicion:
        f.write(f"- {p} [{classify(Path(p).name)}]\n")
    f.write("\n")

print("=== STEP 145: BUILD REACHABLE GRAPH FROM MAIN ===")
print()

print("=== ENTRYPOINTS ===")
for ep in ENTRYPOINTS:
    print(ep)
print()

print("=== REACHABLE COUNTS ===")
for cls in sorted(reachable_by_class):
    print(f"{cls}={len(reachable_by_class[cls])}")
print(f"TOTAL_REACHABLE={len(reachable)}")
print()

print("=== UNREACHABLE COUNTS ===")
for cls in sorted(unreachable_by_class):
    print(f"{cls}={len(unreachable_by_class[cls])}")
print(f"TOTAL_UNREACHABLE={len(unreachable)}")
print()

print("=== HIGH-SUSPICION UNREACHABLE CANDIDATES ===")
for p in high_suspicion:
    print(f"{p} | class={classify(Path(p).name)}")
print()

print("=== REACHABLE PROGRAM/FB CORE ===")
for src in sorted(reachable):
    cls = classify(Path(src).name)
    if cls in {"MAIN", "PROGRAM", "FUNCTION_BLOCK"}:
        print(f"--- {src} [{cls}] ---")
        for d in adj.get(src, []):
            if d in reachable:
                print(f"  -> {d} [{classify(Path(d).name)}]")
        print()

print("=== ARTIFACT ===")
print(md_path.as_posix())
print()

print("=== END STEP 145 ===")
