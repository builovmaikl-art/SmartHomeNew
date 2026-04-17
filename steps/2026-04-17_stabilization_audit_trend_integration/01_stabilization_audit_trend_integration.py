from pathlib import Path
import re

FILES = [
    "PRG_System.st",
    "FB_Trend_Logger.st",
    "FB_Trend_Analyzer.st",
    "FB_Trend_Adapter.st",
    "ST_Trend_Config.dut",
    "ST_Trend_Data.dut",
    "ST_Trend_Header.dut",
    "ST_Trend_History_Record.dut",
    "E_Trend_Parameter_Type.dut",
]

TREND_PATTERNS = [
    r"\bL_Trend_Logger\b",
    r"\bL_Trend_Adapter\b",
    r"\bL_Trend_Data\b",
    r"\bL_Trend_Avg\b",
    r"\bL_Trend_Min\b",
    r"\bL_Trend_Max\b",
    r"\bL_Trend_Up\b",
    r"\bL_Trend_Down\b",
    r"\bL_Trend_Write\b",
    r"\bL_Trend_Write_Prev\b",
    r"\bFB_Trend_Logger\b",
    r"\bFB_Trend_Analyzer\b",
    r"\bFB_Trend_Adapter\b",
    r"\bST_Trend_Data\b",
    r"\bST_Trend_Config\b",
    r"\bE_Trend_Parameter_Type\b",
]

def read(path):
    try:
        return Path(path).read_text(encoding="utf-8")
    except Exception:
        return ""

print("=== STEP 160: STABILIZATION AUDIT TREND INTEGRATION ===")
print()

for f in FILES:
    p = Path(f)
    print(f"--- FILE: {f} ---")
    print(f"exists={p.exists()}")
    if not p.exists():
        print()
        continue

    text = read(f)
    print(f"line_count={len(text.splitlines())}")

    if f == "PRG_System.st":
        print("trend_symbol_counts:")
        for pat in TREND_PATTERNS:
            name = pat.replace(r"\b", "")
            count = len(re.findall(pat, text))
            print(f"  {name}={count}")
        print()

        print("trend_lines:")
        for i, line in enumerate(text.splitlines(), start=1):
            if "Trend" in line or "TREND" in line or "L_Trend_" in line or "FB_Trend_" in line or "ST_Trend_" in line:
                print(f"{i}: {line}")
        print()

        print("history_bridge_lines:")
        for i, line in enumerate(text.splitlines(), start=1):
            if "L_History_Write_Event" in line or "L_History_Event" in line:
                print(f"{i}: {line}")
        print()

    else:
        print("preview:")
        for line in text.splitlines()[:40]:
            print(line)
        if len(text.splitlines()) > 40:
            print("...")
        print()

print("=== SIMPLE FINDINGS ===")
prg = read("PRG_System.st")

checks = {
    "has_trend_logger_instance": "L_Trend_Logger" in prg,
    "has_trend_adapter_instance": "L_Trend_Adapter" in prg,
    "has_direct_trend_analyzer_call": "L_Trend_Analyzer(" in prg,
    "has_adapter_call": "L_Trend_Adapter(" in prg,
    "has_trend_history_bridge": "L_Trend_Event" in prg and "L_History_Event := L_Trend_Event;" in prg,
    "has_duplicate_avg_decl": prg.count("L_Trend_Avg : REAL;") > 1,
    "has_duplicate_min_decl": prg.count("L_Trend_Min : REAL;") > 1,
    "has_duplicate_max_decl": prg.count("L_Trend_Max : REAL;") > 1,
    "has_duplicate_up_decl": prg.count("L_Trend_Up : BOOL;") > 1,
    "has_duplicate_down_decl": prg.count("L_Trend_Down : BOOL;") > 1,
}

for k, v in checks.items():
    print(f"{k}={v}")
print()

print("=== END STEP 160 ===")
