from pathlib import Path

# ------------------------------------------------------------
# 1) Extend GVL_Safety_Selector.gvl with thresholds/policy
# ------------------------------------------------------------
gvl = Path("GVL_Safety_Selector.gvl")
gvl_text = gvl.read_text(encoding="utf-8")

anchor = """    G_Smoke_Effective : BOOL;
"""

insert = """    G_Smoke_Effective : BOOL;

    // === SHADOW QUALITY THRESHOLDS / POLICY ===
    G_CO_Shadow_Max_Diff : REAL := 5.0;
    G_Methane_Shadow_Max_Diff : REAL := 5.0;
    G_Block_Shadow_On_Mismatch : BOOL := TRUE;
"""

if "G_CO_Shadow_Max_Diff" not in gvl_text:
    if anchor not in gvl_text:
        raise SystemExit("Anchor not found in GVL_Safety_Selector.gvl")
    gvl_text = gvl_text.replace(anchor, insert, 1)

gvl.write_text(gvl_text, encoding="utf-8")

# ------------------------------------------------------------
# 2) Patch PRG_System.st quality block
# ------------------------------------------------------------
prg = Path("PRG_System.st")
text = prg.read_text(encoding="utf-8")

old = """// === SHADOW SAFETY QUALITY FLAGS ===
GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Unstable := GVL_Safety_Bridge.G_CO_Diff > 5.0;
GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Unstable := GVL_Safety_Bridge.G_Methane_Diff > 5.0;
GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Mismatch := GVL_Safety_Bridge.G_Smoke_Diff;

IF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Mismatch THEN
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Quality_Text := 'Smoke shadow mismatch';
ELSIF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Unstable THEN
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Quality_Text := 'Methane shadow unstable';
ELSIF GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Unstable THEN
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Quality_Text := 'CO shadow unstable';
ELSE
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Quality_Text := 'Shadow safety quality OK';
END_IF;
"""

new = """// === SHADOW SAFETY QUALITY FLAGS ===
GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Unstable :=
    GVL_Safety_Bridge.G_CO_Diff > GVL_Safety_Selector.G_CO_Shadow_Max_Diff;

GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Unstable :=
    GVL_Safety_Bridge.G_Methane_Diff > GVL_Safety_Selector.G_Methane_Shadow_Max_Diff;

GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Mismatch :=
    GVL_Safety_Bridge.G_Smoke_Diff;

// === SHADOW SAFETY POLICY ===
IF GVL_Safety_Selector.G_Block_Shadow_On_Mismatch THEN
    IF GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Unstable THEN
        GVL_Safety_Selector.G_Use_Shadow_CO := FALSE;
    END_IF;

    IF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Unstable THEN
        GVL_Safety_Selector.G_Use_Shadow_Methane := FALSE;
    END_IF;

    IF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Mismatch THEN
        GVL_Safety_Selector.G_Use_Shadow_Smoke := FALSE;
    END_IF;
END_IF;

IF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Mismatch THEN
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Quality_Text := 'Smoke shadow mismatch';
ELSIF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Unstable THEN
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Quality_Text := 'Methane shadow unstable';
ELSIF GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Unstable THEN
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Quality_Text := 'CO shadow unstable';
ELSE
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Quality_Text := 'Shadow safety quality OK';
END_IF;
"""

if old not in text:
    raise SystemExit("Existing SHADOW SAFETY QUALITY FLAGS block not found in PRG_System.st")

text = text.replace(old, new, 1)
prg.write_text(text, encoding="utf-8")

print("OK: added configurable thresholds and simple shadow safety policy")
