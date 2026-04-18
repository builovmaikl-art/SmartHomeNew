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
    ".git/",
)

ENTRYPOINTS = ["MAIN.st"]

PROTECTED = {
    "MAIN.st",
    "PRG_PLC_A.st",
    "PRG_PLC_B.st",
    "PRG_System.st",
    "FB_Trend_Logger.st",
    "FB_Trend_Analyzer.st",
    "FB_Trend_Adapter.st",
    "ST_Trend_Config.dut",
    "ST_Trend_Data.dut",
    "ST_Trend_Header.dut",
    "ST_Trend_History_Record.dut",
    "E_Trend_Parameter_Type.dut",
    "GVL_Trend.gvl",
}

TREND_CLUSTER = {
    "FB_Trend_Logger.st",
    "FB_Trend_Analyzer.st",
    "FB_Trend_Adapter.st",
    "ST_Trend_Config.dut",
    "ST_Trend_Data.dut",
    "ST_Trend_Header.dut",
    "ST_Trend_History_Record.dut",
    "E_Trend_Parameter_Type.dut",
    "GVL_Trend.gvl",
}

def git_ls():
    out = subprocess.check_output(
        ["git", "ls-files", "*.st", "*.dut", "*.gvl", "**/*.st", "**/*.dut", "**/*.gvl"],
        text=True
    )
    return [x.strip() for x in out.splitlines() if x.strip()]

def is_live(path_str: str) -> bool:
    return not path_str.startswith(EXCLUDED_PREFIXES)

def is_root_code(path_str: str) -> bool:
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

all_files = [p for p in git_ls() if is_live(p)]
root_files = sorted([p for p in all_files if is_root_code(p)])
texts = {p: read_text(p) for p in all_files}
symbols = {Path(p).stem: p for p in root_files}

adj = defaultdict(set)
rev = defaultdict(set)

for src in root_files:
    text = texts.get(src, "")
    for sym, dst in symbols.items():
        if src == dst:
            continue
        if re.search(r"\b" + re.escape(sym) + r"\b", text):
            adj[src].add(dst)
            rev[dst].add(src)

reachable = set()
q = deque()

for ep in ENTRYPOINTS:
    if ep in root_files:
        reachable.add(ep)
        q.append(ep)

while q:
    node = q.popleft()
    for nxt in sorted(adj.get(node, [])):
        if nxt not in reachable:
            reachable.add(nxt)
            q.append(nxt)

unreachable = sorted(set(root_files) - reachable)

reachable_by_class = defaultdict(list)
unreachable_by_class = defaultdict(list)

for p in sorted(reachable):
    reachable_by_class[classify(Path(p).name)].append(p)

for p in unreachable:
    unreachable_by_class[classify(Path(p).name)].append(p)

high_suspicion = [
    p for p in unreachable
    if Path(p).name not in PROTECTED
]

trend_reachable = sorted([p for p in TREND_CLUSTER if p in reachable])
trend_unreachable = sorted([p for p in TREND_CLUSTER if p in unreachable])

# coarse thematic buckets for remaining unreachable
buckets = defaultdict(list)
for p in high_suspicion:
    name = Path(p).name.lower()
    if "snapshot" in name:
        buckets["SNAPSHOT"].append(p)
    elif "presence" in name:
        buckets["PRESENCE"].append(p)
    elif "maintenance" in name or "access" in name:
        buckets["MAINTENANCE_ACCESS"].append(p)
    elif "sensor" in name or "detector" in name or "gas_" in name or "smoke_" in name:
        buckets["SENSORS_SAFETY_LEAFS"].append(p)
    elif "security" in name or "zone_" in name:
        buckets["SECURITY_ZONE"].append(p)
    elif "lifetime" in name:
        buckets["LIFETIME"].append(p)
    elif "rule" in name:
        buckets["RULES"].append(p)
    else:
        buckets["OTHER"].append(p)

print("=== STEP 179: POST-TREND REACHABLE / UNREACHABLE AUDIT ===")
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

print("=== TREND CLUSTER STATUS ===")
print(f"trend_reachable_count={len(trend_reachable)}")
for p in trend_reachable:
    print(f"  REACHABLE: {p}")
print(f"trend_unreachable_count={len(trend_unreachable)}")
for p in trend_unreachable:
    print(f"  UNREACHABLE: {p}")
print()

print("=== HIGH-SUSPICION UNREACHABLE (EXCLUDING PROTECTED) ===")
for p in high_suspicion:
    print(f"{p} | class={classify(Path(p).name)}")
print()

print("=== UNREACHABLE BUCKETS ===")
for bucket in sorted(buckets):
    print(f"--- {bucket} ---")
    for p in sorted(buckets[bucket]):
        print(p)
    print()

print("=== SELECTED REACHABLE CORE EDGES ===")
for src in ["MAIN.st", "PRG_System.st", "PRG_Heating.st", "PRG_Lighting.st", "PRG_Ventilation.st"]:
    if src in root_files:
        print(f"--- {src} ---")
        for d in sorted(adj.get(src, [])):
            if d in reachable:
                print(f"  -> {d} [{classify(Path(d).name)}]")
        print()

print("=== END STEP 179 ===")
