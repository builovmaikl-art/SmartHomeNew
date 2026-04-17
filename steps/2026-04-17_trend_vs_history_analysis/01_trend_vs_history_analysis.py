from pathlib import Path
import re

TREND_FILES = [
    "FB_Trend_Logger.st",
    "FB_Trend_Analyzer.st",
    "ST_Trend_Config.dut",
    "ST_Trend_Data.dut",
    "ST_Trend_Header.dut",
    "ST_Trend_History_Record.dut",
    "E_Trend_Parameter_Type.dut",
]

LIVE_FILES = [
    "FB_History_Manager.st",
    "FB_BlackBox_Recorder.st",
    "FB_NVRAM_Manager.st",
    "ST_History_Record.dut",
    "ST_System_State_Snapshot.dut",
]

def read(p):
    try:
        return Path(p).read_text(encoding="utf-8")
    except:
        return ""

def extract_keywords(text):
    tokens = re.findall(r"\b[A-Za-z_]{4,}\b", text)
    return set(tokens)

print("=== STEP 149: TREND VS HISTORY ANALYSIS ===")
print()

trend_tokens = set()
for f in TREND_FILES:
    text = read(f)
    t = extract_keywords(text)
    trend_tokens |= t
    print(f"--- {f} --- tokens={len(t)}")

print()
live_tokens = set()
for f in LIVE_FILES:
    text = read(f)
    t = extract_keywords(text)
    live_tokens |= t
    print(f"--- {f} --- tokens={len(t)}")

print()

overlap = trend_tokens & live_tokens
trend_only = trend_tokens - live_tokens

print("=== OVERLAP TOKENS ===")
print(len(overlap))
print(sorted(list(overlap))[:50])
print()

print("=== TREND-ONLY TOKENS (potential gap indicators) ===")
print(len(trend_only))
print(sorted(list(trend_only))[:50])
print()

print("=== GAP SIGNAL WORDS ===")
for word in sorted(trend_only):
    if any(k in word.lower() for k in ["trend", "average", "min", "max", "deviation", "history", "buffer"]):
        print(word)

print()

print("=== END STEP 149 ===")
