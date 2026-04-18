from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

bad = """IF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Mismatch THEN
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

IF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Mismatch THEN
        GVL_Safety_Selector.G_Use_Shadow_Smoke := FALSE;
    END_IF;
END_IF;
"""

if bad not in text:
    raise SystemExit("Exact duplicated policy tail not found in PRG_System.st")

text = text.replace(bad, "", 1)
path.write_text(text, encoding="utf-8")
print("OK: removed exact duplicated policy tail and extra END_IF")
