from pathlib import Path

# -------------------------
# 1. Extend GVL_HEATING_REQUEST
# -------------------------
gvl = Path("GVL_HEATING_REQUEST.st")
text = gvl.read_text(encoding="utf-8")

if "G_Freeze_Request" not in text:
    text = text.replace(
        "VAR_GLOBAL",
        "VAR_GLOBAL\n    G_Freeze_Request : BOOL := FALSE;\n    G_Target_Temperature : REAL := 0.0;"
    )

gvl.write_text(text, encoding="utf-8")

# -------------------------
# 2. Add arbitration in PRG_Heating
# -------------------------
prg = Path("PRG_Heating.st")
text = prg.read_text(encoding="utf-8")

block = """

// --- HEATING PRIORITY ARBITRATION ---
IF GVL_HEATING_REQUEST.G_Freeze_Request THEN
    GVL_HEATING_REQUEST.G_Target_Temperature := 5.0;
ELSIF GVL_HEATING_REQUEST.G_Preheat_Request THEN
    GVL_HEATING_REQUEST.G_Target_Temperature := 22.0;
ELSE
    GVL_HEATING_REQUEST.G_Target_Temperature := 20.0;
END_IF;
"""

if "HEATING PRIORITY ARBITRATION" not in text:
    text += block

# -------------------------
# 3. Pass target into Heating Manager
# -------------------------
if "Target_Temperature" not in text:
    text = text.replace(
        "fbHeatingManager(",
        "fbHeatingManager(\n    VI_Preheat_Request := GVL_HEATING_REQUEST.G_Preheat_Request,"
    )

prg.write_text(text, encoding="utf-8")

print("OK: heating priority arbitration added")
