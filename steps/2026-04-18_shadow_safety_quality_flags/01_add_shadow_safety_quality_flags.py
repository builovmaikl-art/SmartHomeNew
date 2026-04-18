from pathlib import Path

# ------------------------------------------------------------
# 1) Extend ST_System_Diagnostics.dut
# ------------------------------------------------------------
dut = Path("ST_System_Diagnostics.dut")
text = dut.read_text(encoding="utf-8")

anchor = """    Sensor_Shadow_Smoke_Active : BOOL;
    Sensor_Shadow_Smoke_Status_Text : STRING(80);
"""

insert = """    Sensor_Shadow_Smoke_Active : BOOL;
    Sensor_Shadow_Smoke_Status_Text : STRING(80);

    Sensor_Shadow_CO_Unstable : BOOL;
    Sensor_Shadow_Methane_Unstable : BOOL;
    Sensor_Shadow_Smoke_Mismatch : BOOL;
    Sensor_Shadow_Quality_Text : STRING(160);
"""

if "Sensor_Shadow_CO_Unstable" not in text:
    if anchor not in text:
        raise SystemExit("Shadow diagnostics anchor not found in ST_System_Diagnostics.dut")
    text = text.replace(anchor, insert, 1)

dut.write_text(text, encoding="utf-8")

# ------------------------------------------------------------
# 2) Patch PRG_System.st
# ------------------------------------------------------------
prg = Path("PRG_System.st")
text = prg.read_text(encoding="utf-8")

marker = "// === LIFETIME UPDATE ==="
if marker not in text:
    raise SystemExit("LIFETIME marker not found in PRG_System.st")

block = """// === SHADOW SAFETY QUALITY FLAGS ===
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

if "// === SHADOW SAFETY QUALITY FLAGS ===" not in text:
    text = text.replace(marker, block + marker, 1)

prg.write_text(text, encoding="utf-8")
print("OK: added shadow safety quality flags")
