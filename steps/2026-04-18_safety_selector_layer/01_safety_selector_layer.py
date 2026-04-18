from pathlib import Path

# ------------------------------------------------------------
# 1) Create selector GVL
# ------------------------------------------------------------
Path("GVL_Safety_Selector.gvl").write_text(
"""VAR_GLOBAL
    // === CONFIG SWITCHES ===
    G_Use_Shadow_CO : BOOL := FALSE;
    G_Use_Shadow_Methane : BOOL := FALSE;
    G_Use_Shadow_Smoke : BOOL := FALSE;

    // === EFFECTIVE SIGNALS ===
    G_CO_Effective : REAL;
    G_Methane_Effective : REAL;
    G_Smoke_Effective : BOOL;
END_VAR
""",
    encoding="utf-8"
)

# ------------------------------------------------------------
# 2) Patch PRG_System.st
# ------------------------------------------------------------
path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

marker = "// === LIFETIME UPDATE ==="
if marker not in text:
    raise SystemExit("LIFETIME marker not found")

selector_block = """// === SAFETY SELECTOR LAYER ===

// CO
IF GVL_Safety_Selector.G_Use_Shadow_CO THEN
    GVL_Safety_Selector.G_CO_Effective := GVL_Sensor_Shadow.G_CO_Calibrated;
ELSE
    GVL_Safety_Selector.G_CO_Effective := GVL_STATE.G_CO_Sensors[1];
END_IF;

// METHANE
IF GVL_Safety_Selector.G_Use_Shadow_Methane THEN
    GVL_Safety_Selector.G_Methane_Effective := GVL_Sensor_Shadow.G_Methane_Calibrated;
ELSE
    GVL_Safety_Selector.G_Methane_Effective := GVL_STATE.G_Methane_Sensors[1];
END_IF;

// SMOKE
IF GVL_Safety_Selector.G_Use_Shadow_Smoke THEN
    GVL_Safety_Selector.G_Smoke_Effective := GVL_Sensor_Shadow.G_Smoke_Detected;
ELSE
    GVL_Safety_Selector.G_Smoke_Effective := GVL_STATE.G_Smoke_Sensors[1];
END_IF;

"""

if "// === SAFETY SELECTOR LAYER ===" not in text:
    text = text.replace(marker, selector_block + marker, 1)

path.write_text(text, encoding="utf-8")

print("OK: safety selector layer added")
