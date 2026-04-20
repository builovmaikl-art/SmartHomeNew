from pathlib import Path

# -------------------------
# 1. Create GVL_HEATING_REQUEST
# -------------------------
gvl_path = Path("GVL_HEATING_REQUEST.st")

if not gvl_path.exists():
    gvl_path.write_text("""VAR_GLOBAL
    G_Preheat_Request : BOOL := FALSE;
END_VAR
""", encoding="utf-8")

# -------------------------
# 2. PRG_System — write to GVL
# -------------------------
prg_sys = Path("PRG_System.st")
text = prg_sys.read_text(encoding="utf-8")

insert = """
// --- HEATING REQUEST LAYER ---
GVL_HEATING_REQUEST.G_Preheat_Request := fbRuleEngine.VO_Preheat_Request;
"""

if "HEATING REQUEST LAYER" not in text:
    text += insert

prg_sys.write_text(text, encoding="utf-8")

# -------------------------
# 3. PRG_Heating — read from GVL
# -------------------------
prg_heat = Path("PRG_Heating.st")
text = prg_heat.read_text(encoding="utf-8")

old = "VI_Preheat_Request :="

if "GVL_HEATING_REQUEST.G_Preheat_Request" not in text:
    text = text.replace(
        "fbHeatingManager(",
        "fbHeatingManager(\n    VI_Preheat_Request := GVL_HEATING_REQUEST.G_Preheat_Request,"
    )

prg_heat.write_text(text, encoding="utf-8")

print("OK: heating request layer integrated via GVL")
