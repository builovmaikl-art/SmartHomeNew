from pathlib import Path

# ------------------------------------------------------------
# 1) Extend GVL_Safety_Selector (counters + thresholds)
# ------------------------------------------------------------
gvl = Path("GVL_Safety_Selector.gvl")
text = gvl.read_text(encoding="utf-8")

anchor = "G_Block_Shadow_On_Mismatch : BOOL := TRUE;"

insert = """G_Block_Shadow_On_Mismatch : BOOL := TRUE;

    // === DEBOUNCE POLICY ===
    G_Shadow_Unstable_Cycles_Limit : INT := 5;

    G_CO_Unstable_Counter : INT := 0;
    G_Methane_Unstable_Counter : INT := 0;
    G_Smoke_Unstable_Counter : INT := 0;
"""

if "G_Shadow_Unstable_Cycles_Limit" not in text:
    if anchor not in text:
        raise SystemExit("Anchor not found in GVL_Safety_Selector.gvl")
    text = text.replace(anchor, insert, 1)

gvl.write_text(text, encoding="utf-8")

# ------------------------------------------------------------
# 2) Patch PRG_System debounce logic
# ------------------------------------------------------------
prg = Path("PRG_System.st")
text = prg.read_text(encoding="utf-8")

policy_marker = "// === SHADOW SAFETY POLICY ==="
if policy_marker not in text:
    raise SystemExit("Policy block not found")

debounce_block = """// === SHADOW SAFETY POLICY (DEBOUNCE) ===
IF GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Unstable THEN
    GVL_Safety_Selector.G_CO_Unstable_Counter := GVL_Safety_Selector.G_CO_Unstable_Counter + 1;
ELSE
    GVL_Safety_Selector.G_CO_Unstable_Counter := 0;
END_IF;

IF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Unstable THEN
    GVL_Safety_Selector.G_Methane_Unstable_Counter := GVL_Safety_Selector.G_Methane_Unstable_Counter + 1;
ELSE
    GVL_Safety_Selector.G_Methane_Unstable_Counter := 0;
END_IF;

IF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Mismatch THEN
    GVL_Safety_Selector.G_Smoke_Unstable_Counter := GVL_Safety_Selector.G_Smoke_Unstable_Counter + 1;
ELSE
    GVL_Safety_Selector.G_Smoke_Unstable_Counter := 0;
END_IF;

// apply fallback only after N cycles
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
"""

# заменить старый policy block целиком
start = text.find(policy_marker)
end = text.find("IF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Mismatch", start)

if start == -1 or end == -1:
    raise SystemExit("Cannot isolate policy block")

text = text[:start] + debounce_block + "\n" + text[end:]
prg.write_text(text, encoding="utf-8")

print("OK: debounce policy applied")
