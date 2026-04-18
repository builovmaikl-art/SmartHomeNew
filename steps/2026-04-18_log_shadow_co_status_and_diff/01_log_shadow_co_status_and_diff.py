from pathlib import Path

# ------------------------------------------------------------
# Patch PRG_System.st
# ------------------------------------------------------------
path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

marker = "// === LIFETIME UPDATE ==="
if marker not in text:
    raise SystemExit("LIFETIME marker not found in PRG_System.st")

block = """// === SHADOW CO DIAGNOSTIC EXPORT ===
GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Active := GVL_Safety_Selector.G_Use_Shadow_CO;
GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Diff := GVL_Safety_Bridge.G_CO_Diff;

IF GVL_Safety_Selector.G_Use_Shadow_CO THEN
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Status_Text := 'CO shadow ACTIVE';
ELSE
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Status_Text := 'CO shadow OFF';
END_IF;

"""

if "Sensor_Shadow_CO_Active" not in text:
    text = text.replace(marker, block + marker, 1)

path.write_text(text, encoding="utf-8")
print("OK: added shadow CO diagnostic export to PRG_System")
