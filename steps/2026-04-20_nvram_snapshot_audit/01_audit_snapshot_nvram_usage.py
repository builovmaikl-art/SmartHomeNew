#!/usr/bin/env python3
import os
from datetime import datetime

ROOT = "."
OUT_DIR = "repo_logs/nvram/2026_04_20"
os.makedirs(OUT_DIR, exist_ok=True)

def scan(patterns):
    results = []
    for root, _, files in os.walk(ROOT):
        for f in files:
            if f.endswith((".st", ".gvl", ".dut")):
                path = os.path.join(root, f)
                try:
                    with open(path, "r", encoding="utf-8", errors="ignore") as fh:
                        lines = fh.readlines()
                        for i, line in enumerate(lines):
                            for p in patterns:
                                if p in line:
                                    results.append(f"{path}:{i+1}: {line.strip()}")
                except:
                    pass
    return results

def write(name, lines):
    with open(os.path.join(OUT_DIR, name), "w", encoding="utf-8") as f:
        f.write("\n".join(lines))

# 1. Snapshot usage
snapshot = scan([
    "ST_State_Snapshot",
    "FB_State_Snapshot",
    "Snapshot"
])
write("snapshot_usage.log", snapshot)

# 2. NVRAM usage
nvram = scan([
    "FB_NVRAM_Manager",
    "NVRAM",
    "G_NVRAM_Data"
])
write("nvram_usage.log", nvram)

# 3. PRG_System integration
prg = []
if os.path.exists("PRG_System.st"):
    with open("PRG_System.st", "r", encoding="utf-8", errors="ignore") as f:
        for i, line in enumerate(f.readlines()):
            if any(k in line for k in ["Snapshot", "NVRAM", "Save", "Restore"]):
                prg.append(f"PRG_System.st:{i+1}: {line.strip()}")
write("prg_system_integration.log", prg)

# 4. RETAIN layout
retain = scan([
    "GVL_Retain",
    "RETAIN",
    "G_NVRAM_Data"
])
write("retain_layout.log", retain)

# 5. Summary (минимальная интерпретация)
summary = []
summary.append("=== FILE PRESENCE ===")

summary.append(f"FB_NVRAM_Manager.st: {'YES' if os.path.exists('FB_NVRAM_Manager.st') else 'NO'}")
summary.append(f"FB_State_Snapshot_NVRAM.st: {'YES' if os.path.exists('FB_State_Snapshot_NVRAM.st') else 'NO'}")

summary.append("")
summary.append("=== QUICK SIGNALS ===")

summary.append(f"Snapshot refs: {len(snapshot)}")
summary.append(f"NVRAM refs: {len(nvram)}")
summary.append(f"PRG refs: {len(prg)}")
summary.append(f"RETAIN refs: {len(retain)}")

write("persistence_path_summary.log", summary)

print("DONE")
