from pathlib import Path

# -------------------------
# 1. PRG_System: remove orphan tail line
# -------------------------
prg = Path("PRG_System.st")
text = prg.read_text(encoding="utf-8")

orphan = "    (GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_FREEZE_PROTECTION);\n"
text = text.replace(orphan, "")
text = text.replace("(GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_FREEZE_PROTECTION);\n", "")

prg.write_text(text, encoding="utf-8")

# -------------------------
# 2. GVL_STATE: add missing heating request vars
# -------------------------
gvl = Path("GVL_STATE.gvl")
text = gvl.read_text(encoding="utf-8")

insert_anchor = "    G_Water_Zone_Exercise_Active : ARRAY[1..32] OF BOOL; // Профилактическая прокрутка шаровых кранов\n"
insert_block = """    G_Water_Zone_Exercise_Active : ARRAY[1..32] OF BOOL; // Профилактическая прокрутка шаровых кранов
    G_Preheat_Request : BOOL; // Heating request: preheat
    G_Freeze_Request : BOOL; // Heating request: freeze
    G_Target_Temperature : REAL; // Heating arbitration target
"""

if "G_Target_Temperature" not in text:
    if insert_anchor not in text:
        raise SystemExit("Anchor not found in GVL_STATE.gvl")
    text = text.replace(insert_anchor, insert_block, 1)
    gvl.write_text(text, encoding="utf-8")

print("OK: removed orphan PRG_System tail and added heating request vars to GVL_STATE.gvl")
