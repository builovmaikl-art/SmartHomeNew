from pathlib import Path

# ------------------------------------------------------------
# 1) Extend GVL_Safety_Selector.gvl with effective arrays
# ------------------------------------------------------------
gvl_path = Path("GVL_Safety_Selector.gvl")
gvl_text = gvl_path.read_text(encoding="utf-8")

insert = """
    // === EFFECTIVE ARRAYS FOR SAFETY FB ===
    G_CO_Effective_Array : ARRAY[1..GVL_CONSTANTS.C_MAX_CO_SENSORS] OF REAL;
    G_Methane_Effective_Array : ARRAY[1..GVL_CONSTANTS.C_MAX_METHANE_SENSORS] OF REAL;
    G_Smoke_Effective_Array : ARRAY[1..GVL_CONSTANTS.C_MAX_SMOKE_SENSORS] OF BOOL;
"""

if "G_CO_Effective_Array" not in gvl_text:
    gvl_text = gvl_text.replace("END_VAR", insert + "\nEND_VAR")

gvl_path.write_text(gvl_text, encoding="utf-8")

# ------------------------------------------------------------
# 2) Add loop index variable to PRG_System.st
# ------------------------------------------------------------
prg_system = Path("PRG_System.st")
sys_text = prg_system.read_text(encoding="utf-8")

anchor = "L_CO_Calibrated : REAL;"
if anchor not in sys_text:
    raise SystemExit("Anchor for selector loop var not found in PRG_System.st")

if "L_Safety_Selector_i : INT;" not in sys_text:
    sys_text = sys_text.replace(
        anchor,
        anchor + "\nL_Safety_Selector_i : INT;",
        1
    )

# ------------------------------------------------------------
# 3) Fill effective arrays in selector block
# ------------------------------------------------------------
selector_anchor = "// === SAFETY SELECTOR LAYER ==="
if selector_anchor not in sys_text:
    raise SystemExit("Selector block not found in PRG_System.st")

selector_snippet = """// === SAFETY SELECTOR LAYER ===

// base copy from runtime arrays
FOR L_Safety_Selector_i := 1 TO GVL_CONSTANTS.C_MAX_CO_SENSORS DO
    GVL_Safety_Selector.G_CO_Effective_Array[L_Safety_Selector_i] := GVL_STATE.G_CO_Sensors[L_Safety_Selector_i];
END_FOR;

FOR L_Safety_Selector_i := 1 TO GVL_CONSTANTS.C_MAX_METHANE_SENSORS DO
    GVL_Safety_Selector.G_Methane_Effective_Array[L_Safety_Selector_i] := GVL_STATE.G_Methane_Sensors[L_Safety_Selector_i];
END_FOR;

FOR L_Safety_Selector_i := 1 TO GVL_CONSTANTS.C_MAX_SMOKE_SENSORS DO
    GVL_Safety_Selector.G_Smoke_Effective_Array[L_Safety_Selector_i] := GVL_STATE.G_Smoke_Sensors[L_Safety_Selector_i];
END_FOR;

// CO
IF GVL_Safety_Selector.G_Use_Shadow_CO THEN
    GVL_Safety_Selector.G_CO_Effective := GVL_Sensor_Shadow.G_CO_Calibrated;
    GVL_Safety_Selector.G_CO_Effective_Array[1] := GVL_Sensor_Shadow.G_CO_Calibrated;
ELSE
    GVL_Safety_Selector.G_CO_Effective := GVL_STATE.G_CO_Sensors[1];
END_IF;

// METHANE
IF GVL_Safety_Selector.G_Use_Shadow_Methane THEN
    GVL_Safety_Selector.G_Methane_Effective := GVL_Sensor_Shadow.G_Methane_Calibrated;
    GVL_Safety_Selector.G_Methane_Effective_Array[1] := GVL_Sensor_Shadow.G_Methane_Calibrated;
ELSE
    GVL_Safety_Selector.G_Methane_Effective := GVL_STATE.G_Methane_Sensors[1];
END_IF;

// SMOKE
IF GVL_Safety_Selector.G_Use_Shadow_Smoke THEN
    GVL_Safety_Selector.G_Smoke_Effective := GVL_Sensor_Shadow.G_Smoke_Detected;
    GVL_Safety_Selector.G_Smoke_Effective_Array[1] := GVL_Sensor_Shadow.G_Smoke_Detected;
ELSE
    GVL_Safety_Selector.G_Smoke_Effective := GVL_STATE.G_Smoke_Sensors[1];
END_IF;

"""

# replace existing selector block up to lifetime marker
lifetime_marker = "// === LIFETIME UPDATE ==="
start = sys_text.find(selector_anchor)
end = sys_text.find(lifetime_marker)
if start == -1 or end == -1 or end <= start:
    raise SystemExit("Could not isolate selector block in PRG_System.st")

sys_text = sys_text[:start] + selector_snippet + "\n" + sys_text[end:]
prg_system.write_text(sys_text, encoding="utf-8")

# ------------------------------------------------------------
# 4) Switch PRG_Safety.st GasSmokeManager call to effective arrays
# ------------------------------------------------------------
prg_safety = Path("PRG_Safety.st")
safety_text = prg_safety.read_text(encoding="utf-8")

old = """    VI_Methane_LEL := GVL_STATE.G_Methane_Sensors,
    VI_CO_PPM := GVL_STATE.G_CO_Sensors,
    VI_Smoke_Sensors := GVL_STATE.G_Smoke_Sensors,
"""

new = """    VI_Methane_LEL := GVL_Safety_Selector.G_Methane_Effective_Array,
    VI_CO_PPM := GVL_Safety_Selector.G_CO_Effective_Array,
    VI_Smoke_Sensors := GVL_Safety_Selector.G_Smoke_Effective_Array,
"""

if old not in safety_text:
    raise SystemExit("Expected GasSmokeManager array inputs not found in PRG_Safety.st")

safety_text = safety_text.replace(old, new, 1)
prg_safety.write_text(safety_text, encoding="utf-8")

print("OK: partial switch infrastructure via effective arrays applied")
