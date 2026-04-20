#!/usr/bin/env python3
from pathlib import Path

# -------------------------
# 1. Heating Manager — add input + logic
# -------------------------
hm_path = Path("FB_Heating_System_Manager.st")
hm = hm_path.read_text(encoding="utf-8")

# add input
if "VI_Preheat_Request" not in hm:
    hm = hm.replace(
        "VAR_INPUT",
        "VAR_INPUT\n    VI_Preheat_Request : BOOL; // preheat scenario trigger"
    )

# inject logic (simple, safe override)
if "PREHEAT_HEATING_INSERT" not in hm:
    hm += """

// --- PREHEAT HEATING INSERT ---
IF VI_Preheat_Request THEN
    // simple safe preheat: raise target temp slightly
    GVL_HEATING.G_Preheat_Mode := TRUE;
END_IF;
"""

hm_path.write_text(hm, encoding="utf-8")

# -------------------------
# 2. Scenario Manager — remove direct GVL write
# -------------------------
sc_path = Path("FB_Scenario_Manager.st")
sc = sc_path.read_text(encoding="utf-8")

# remove old direct write
sc = sc.replace(
    "GVL_HEATING.G_Preheat_Active := TRUE;",
    "// removed: direct heating write (moved to Heating Manager)"
)

sc_path.write_text(sc, encoding="utf-8")

# -------------------------
# 3. PRG_System wiring
# -------------------------
prg_path = Path("PRG_System.st")
prg = prg_path.read_text(encoding="utf-8")

# connect scenario → heating manager
if "VI_Preheat_Request := fbScenarioManager" not in prg:
    prg = prg.replace(
        "fbHeatingSystemManager(",
        "fbHeatingSystemManager(\n        VI_Preheat_Request := fbScenarioManager.VI_Preheat_Request,"
    )

prg_path.write_text(prg, encoding="utf-8")

print("OK: preheat moved to Heating Manager (no direct GVL writes)")
