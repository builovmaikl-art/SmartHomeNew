from pathlib import Path

# -------------------------
# 1. PRG_System → Freeze signal
# -------------------------
prg_sys = Path("PRG_System.st")
text = prg_sys.read_text(encoding="utf-8")

block = """
// --- FREEZE REQUEST ---
GVL_HEATING_REQUEST.G_Freeze_Request :=
    (GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_FREEZE_PROTECTION);
"""

if "FREEZE REQUEST" not in text:
    text += block

prg_sys.write_text(text, encoding="utf-8")

# -------------------------
# 2. PRG_Heating → strengthen arbitration
# -------------------------
prg_heat = Path("PRG_Heating.st")
text = prg_heat.read_text(encoding="utf-8")

block = """

// --- HEATING FINAL TARGET ---
IF GVL_HEATING_REQUEST.G_Freeze_Request THEN
    GVL_HEATING_REQUEST.G_Target_Temperature := 5.0;
ELSIF GVL_HEATING_REQUEST.G_Preheat_Request THEN
    GVL_HEATING_REQUEST.G_Target_Temperature := 22.0;
ELSE
    GVL_HEATING_REQUEST.G_Target_Temperature := 20.0;
END_IF;
"""

if "HEATING FINAL TARGET" not in text:
    text += block

prg_heat.write_text(text, encoding="utf-8")

# -------------------------
# 3. Heating Manager → use target
# -------------------------
hm = Path("FB_Heating_System_Manager.st")
text = hm.read_text(encoding="utf-8")

insert = """

// --- HEATING TARGET INJECTION ---
IF GVL_HEATING_REQUEST.G_Target_Temperature > 0.0 THEN
    L_Target_Supply_Temp := GVL_HEATING_REQUEST.G_Target_Temperature;
END_IF;
"""

if "HEATING TARGET INJECTION" not in text:
    text = text.replace(
        "// 2. Расчет целевой температуры подачи теплоносителя",
        insert + "\n// 2. Расчет целевой температуры подачи теплоносителя"
    )

hm.write_text(text, encoding="utf-8")

print("OK: multi-source arbitration v1 applied")
