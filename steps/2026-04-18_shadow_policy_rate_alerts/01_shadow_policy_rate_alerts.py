from pathlib import Path

# ------------------------------------------------------------
# 1) Extend ST_System_Diagnostics.dut with isolated alert layer
# ------------------------------------------------------------
dut = Path("ST_System_Diagnostics.dut")
text = dut.read_text(encoding="utf-8")

anchor = """    Sensor_Shadow_Rate_High_Activity : BOOL;
    Sensor_Shadow_Rate_Summary_Text : STRING(160);
"""
insert = """    Sensor_Shadow_Rate_High_Activity : BOOL;
    Sensor_Shadow_Rate_Summary_Text : STRING(160);

    // === RATE ALERTS (ISOLATED) ===
    Sensor_Shadow_Rate_Alert_Threshold_Per_Hour : REAL;
    Sensor_Shadow_Rate_Alert_Active : BOOL;
    Sensor_Shadow_CO_Rate_Alert_Active : BOOL;
    Sensor_Shadow_Methane_Rate_Alert_Active : BOOL;
    Sensor_Shadow_Smoke_Rate_Alert_Active : BOOL;
    Sensor_Shadow_Rate_Alert_Text : STRING(160);
"""

if "Sensor_Shadow_Rate_Alert_Threshold_Per_Hour" not in text:
    if anchor not in text:
        raise SystemExit("Rate anchor not found in ST_System_Diagnostics.dut")
    text = text.replace(anchor, insert, 1)

dut.write_text(text, encoding="utf-8")

# ------------------------------------------------------------
# 2) Patch PRG_System.st with isolated alert block
# ------------------------------------------------------------
prg = Path("PRG_System.st")
text = prg.read_text(encoding="utf-8")

marker = "// === LIFETIME UPDATE ==="
if marker not in text:
    raise SystemExit("LIFETIME marker not found in PRG_System.st")

block = """// === SHADOW POLICY RATE ALERTS ===
IF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Alert_Threshold_Per_Hour <= 0.0 THEN
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Alert_Threshold_Per_Hour := 10.0;
END_IF;

GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Rate_Alert_Active :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Rate_Fallback_Per_Hour >
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Alert_Threshold_Per_Hour;

GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Rate_Alert_Active :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Rate_Fallback_Per_Hour >
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Alert_Threshold_Per_Hour;

GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Rate_Alert_Active :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Rate_Fallback_Per_Hour >
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Alert_Threshold_Per_Hour;

GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Alert_Active :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Rate_Alert_Active OR
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Rate_Alert_Active OR
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Rate_Alert_Active;

IF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Rate_Alert_Active THEN
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Alert_Text := 'Smoke fallback rate alert';
ELSIF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Rate_Alert_Active THEN
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Alert_Text := 'Methane fallback rate alert';
ELSIF GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Rate_Alert_Active THEN
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Alert_Text := 'CO fallback rate alert';
ELSE
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Alert_Text := 'No shadow rate alerts';
END_IF;

"""

if "// === SHADOW POLICY RATE ALERTS ===" not in text:
    text = text.replace(marker, block + marker, 1)

prg.write_text(text, encoding="utf-8")
print("OK: added isolated shadow policy rate alerts")
