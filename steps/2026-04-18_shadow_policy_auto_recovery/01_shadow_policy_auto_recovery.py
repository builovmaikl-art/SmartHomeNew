from pathlib import Path

# ------------------------------------------------------------
# 1) Extend GVL_Safety_Selector (recovery thresholds + counters)
# ------------------------------------------------------------
gvl = Path("GVL_Safety_Selector.gvl")
text = gvl.read_text(encoding="utf-8")

anchor = "G_Shadow_Unstable_Cycles_Limit : INT := 5;"

insert = """G_Shadow_Unstable_Cycles_Limit : INT := 5;

    // === RECOVERY POLICY (HYSTERESIS) ===
    G_CO_Shadow_Recovery_Diff : REAL := 2.0;
    G_Methane_Shadow_Recovery_Diff : REAL := 2.0;

    G_CO_Stable_Counter : INT := 0;
    G_Methane_Stable_Counter : INT := 0;
    G_Smoke_Stable_Counter : INT := 0;
"""

if "G_CO_Shadow_Recovery_Diff" not in text:
    if anchor not in text:
        raise SystemExit("Anchor not found in GVL_Safety_Selector.gvl")
    text = text.replace(anchor, insert, 1)

gvl.write_text(text, encoding="utf-8")

# ------------------------------------------------------------
# 2) Patch PRG_System recovery logic
# ------------------------------------------------------------
prg = Path("PRG_System.st")
text = prg.read_text(encoding="utf-8")

marker = "// === SHADOW SAFETY POLICY (DEBOUNCE) ==="
if marker not in text:
    raise SystemExit("Debounce policy block not found")

recovery_block = """// === SHADOW SAFETY POLICY (DEBOUNCE + RECOVERY) ===

// --- UNSTABLE COUNTERS ---
IF GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Unstable THEN
    GVL_Safety_Selector.G_CO_Unstable_Counter := GVL_Safety_Selector.G_CO_Unstable_Counter + 1;
    GVL_Safety_Selector.G_CO_Stable_Counter := 0;
ELSE
    GVL_Safety_Selector.G_CO_Unstable_Counter := 0;
END_IF;

IF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Unstable THEN
    GVL_Safety_Selector.G_Methane_Unstable_Counter := GVL_Safety_Selector.G_Methane_Unstable_Counter + 1;
    GVL_Safety_Selector.G_Methane_Stable_Counter := 0;
ELSE
    GVL_Safety_Selector.G_Methane_Unstable_Counter := 0;
END_IF;

IF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Mismatch THEN
    GVL_Safety_Selector.G_Smoke_Unstable_Counter := GVL_Safety_Selector.G_Smoke_Unstable_Counter + 1;
    GVL_Safety_Selector.G_Smoke_Stable_Counter := 0;
ELSE
    GVL_Safety_Selector.G_Smoke_Unstable_Counter := 0;
END_IF;

// --- STABLE COUNTERS (for recovery) ---
IF NOT GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Unstable AND
   GVL_Safety_Bridge.G_CO_Diff < GVL_Safety_Selector.G_CO_Shadow_Recovery_Diff THEN
    GVL_Safety_Selector.G_CO_Stable_Counter := GVL_Safety_Selector.G_CO_Stable_Counter + 1;
END_IF;

IF NOT GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Unstable AND
   GVL_Safety_Bridge.G_Methane_Diff < GVL_Safety_Selector.G_Methane_Shadow_Recovery_Diff THEN
    GVL_Safety_Selector.G_Methane_Stable_Counter := GVL_Safety_Selector.G_Methane_Stable_Counter + 1;
END_IF;

IF NOT GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Mismatch THEN
    GVL_Safety_Selector.G_Smoke_Stable_Counter := GVL_Safety_Selector.G_Smoke_Stable_Counter + 1;
END_IF;

// --- FALLBACK ---
IF GVL_Safety_Selector.G_Block_Shadow_On_Mismatch THEN

    IF GVL_Safety_Selector.G_CO_Unstable_Counter >= GVL_Safety_Selector.G_Shadow_Unstable_Cycles_Limit THEN
        GVL_Safety_Selector.G_Use_Shadow_CO := FALSE;
    END_IF;

    IF GVL_Safety_Selector.G_Methane_Unstable_Counter >= GVL_Safety_Selector.G_Shadow_Unstable_Cycles_Limit THEN
        GVL_Safety_Selector.G_Use_Shadow_Methane := FALSE;
    END_IF;

    IF GVL_Safety_Selector.G_Smoke_Unstable_Counter >= GVL_Safety_Selector.G_Shadow_Unstable_Cycles_Limit THEN
        GVL_Safety_Selector.G_Use_Shadow_Smoke := FALSE;
    END_IF;

END_IF;

// --- RECOVERY ---
IF GVL_Safety_Selector.G_CO_Stable_Counter >= GVL_Safety_Selector.G_Shadow_Unstable_Cycles_Limit THEN
    GVL_Safety_Selector.G_Use_Shadow_CO := TRUE;
END_IF;

IF GVL_Safety_Selector.G_Methane_Stable_Counter >= GVL_Safety_Selector.G_Shadow_Unstable_Cycles_Limit THEN
    GVL_Safety_Selector.G_Use_Shadow_Methane := TRUE;
END_IF;

IF GVL_Safety_Selector.G_Smoke_Stable_Counter >= GVL_Safety_Selector.G_Shadow_Unstable_Cycles_Limit THEN
    GVL_Safety_Selector.G_Use_Shadow_Smoke := TRUE;
END_IF;
"""

# replace entire debounce block
start = text.find(marker)
end = text.find("IF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Mismatch", start)

if start == -1 or end == -1:
    raise SystemExit("Cannot isolate debounce block")

text = text[:start] + recovery_block + "\n" + text[end:]
prg.write_text(text, encoding="utf-8")

print("OK: added auto-recovery hysteresis policy")
