from pathlib import Path

# ------------------------------------------------------------
# 1) Create GVL_Safety_Bridge
# ------------------------------------------------------------
Path("GVL_Safety_Bridge.gvl").write_text(
"""VAR_GLOBAL
    // === CO COMPARISON ===
    G_CO_Runtime : REAL;
    G_CO_Shadow  : REAL;
    G_CO_Diff    : REAL;

    // === METHANE COMPARISON ===
    G_Methane_Runtime : REAL;
    G_Methane_Shadow  : REAL;
    G_Methane_Diff    : REAL;

    // === SMOKE COMPARISON ===
    G_Smoke_Runtime : BOOL;
    G_Smoke_Shadow  : BOOL;
    G_Smoke_Diff    : BOOL;
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

bridge_block = """// === SAFETY SHADOW VS RUNTIME BRIDGE ===

// CO
GVL_Safety_Bridge.G_CO_Runtime := GVL_STATE.G_CO_Sensors[1];
GVL_Safety_Bridge.G_CO_Shadow  := GVL_Sensor_Shadow.G_CO_Calibrated;
GVL_Safety_Bridge.G_CO_Diff    := ABS(GVL_Safety_Bridge.G_CO_Runtime - GVL_Safety_Bridge.G_CO_Shadow);

// METHANE
GVL_Safety_Bridge.G_Methane_Runtime := GVL_STATE.G_Methane_Sensors[1];
GVL_Safety_Bridge.G_Methane_Shadow  := GVL_Sensor_Shadow.G_Methane_Calibrated;
GVL_Safety_Bridge.G_Methane_Diff    := ABS(GVL_Safety_Bridge.G_Methane_Runtime - GVL_Safety_Bridge.G_Methane_Shadow);

// SMOKE
GVL_Safety_Bridge.G_Smoke_Runtime := GVL_STATE.G_Smoke_Sensors[1];
GVL_Safety_Bridge.G_Smoke_Shadow  := GVL_Sensor_Shadow.G_Smoke_Detected;
GVL_Safety_Bridge.G_Smoke_Diff    := GVL_Safety_Bridge.G_Smoke_Runtime XOR GVL_Safety_Bridge.G_Smoke_Shadow;

"""

if "// === SAFETY SHADOW VS RUNTIME BRIDGE ===" not in text:
    text = text.replace(marker, bridge_block + marker, 1)

path.write_text(text, encoding="utf-8")

print("OK: safety shadow vs runtime bridge added")
