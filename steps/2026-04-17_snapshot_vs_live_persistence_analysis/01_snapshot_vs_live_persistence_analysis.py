from pathlib import Path
import re

SNAPSHOT_FILES = [
    "FB_State_Snapshot_Manager.st",
    "FB_State_Snapshot_NVRAM.st",
    "ST_State_Snapshot.dut",
]

LIVE_FILES = [
    "FB_History_Manager.st",
    "FB_BlackBox_Recorder.st",
    "FB_NVRAM_Manager.st",
    "FB_Redundancy_Manager.st",
    "FB_State_Replication.st",
    "ST_History_Record.dut",
    "ST_System_State_Snapshot.dut",
    "GVL_Retain.gvl",
]

def read(p):
    try:
        return Path(p).read_text(encoding="utf-8")
    except Exception:
        return ""

def tokens(text):
    return set(re.findall(r"\b[A-Za-z_][A-Za-z0-9_]*\b", text))

def meaningful(ts):
    skip = {
        "TYPE","STRUCT","END_STRUCT","END_TYPE","FUNCTION_BLOCK",
        "VAR","VAR_INPUT","VAR_OUTPUT","VAR_IN_OUT","END_VAR",
        "IF","THEN","ELSE","END_IF","CASE","OF","END_CASE",
        "FOR","TO","DO","END_FOR","RETURN",
        "BOOL","BYTE","WORD","DWORD","UDINT","UINT","INT","REAL","STRING","ARRAY",
        "attribute","pack_mode","strict",
        "TRUE","FALSE",
    }
    out = set()
    for t in ts:
        if t in skip:
            continue
        if len(t) < 4:
            continue
        out.add(t)
    return out

print("=== STEP 151: SNAPSHOT VS LIVE PERSISTENCE ANALYSIS ===")
print()

snapshot_tokens = set()
for f in SNAPSHOT_FILES:
    text = read(f)
    t = meaningful(tokens(text))
    snapshot_tokens |= t
    print(f"--- {f} ---")
    print(f"token_count={len(t)}")
    print()

live_tokens = set()
for f in LIVE_FILES:
    text = read(f)
    t = meaningful(tokens(text))
    live_tokens |= t
    print(f"--- {f} ---")
    print(f"token_count={len(t)}")
    print()

overlap = sorted(snapshot_tokens & live_tokens)
snapshot_only = sorted(snapshot_tokens - live_tokens)
live_only = sorted(live_tokens - snapshot_tokens)

print("=== OVERLAP TOKENS ===")
print(len(overlap))
print(overlap[:120])
print()

print("=== SNAPSHOT-ONLY TOKENS ===")
print(len(snapshot_only))
print(snapshot_only[:120])
print()

print("=== LIVE-ONLY TOKENS ===")
print(len(live_only))
print(live_only[:120])
print()

print("=== SNAPSHOT GAP SIGNALS ===")
for word in snapshot_only:
    lw = word.lower()
    if any(k in lw for k in [
        "snapshot", "trigger", "event", "saved", "filename", "file",
        "write_idx", "operator_id", "scenario_id", "crc", "lighting", "setpoints"
    ]):
        print(word)
print()

print("=== LIVE COVERAGE SIGNALS ===")
for word in overlap:
    lw = word.lower()
    if any(k in lw for k in [
        "timestamp", "state", "system", "history", "retain", "snapshot", "record"
    ]):
        print(word)
print()

print("=== FILE PREVIEWS ===")
for f in SNAPSHOT_FILES + LIVE_FILES:
    print(f"--- {f} ---")
    text = read(f)
    for line in text.splitlines()[:25]:
        print(line)
    if len(text.splitlines()) > 25:
        print("...")
    print()

print("=== END STEP 151 ===")
