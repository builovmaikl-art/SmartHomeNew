from pathlib import Path

# ------------------------------------------------------------
# 1) Extend ST_System_Diagnostics.dut
# ------------------------------------------------------------
dut = Path("ST_System_Diagnostics.dut")
text = dut.read_text(encoding="utf-8")

anchor = """    Sensor_Shadow_Total_Fallback_Count : UDINT;
    Sensor_Shadow_Total_Recovery_Count : UDINT;
"""
insert = """    Sensor_Shadow_Total_Fallback_Count : UDINT;
    Sensor_Shadow_Total_Recovery_Count : UDINT;

    Sensor_Shadow_CO_Healthy : BOOL;
    Sensor_Shadow_Methane_Healthy : BOOL;
    Sensor_Shadow_Smoke_Healthy : BOOL;
    Sensor_Shadow_Dominant_Channel : STRING(32);
    Sensor_Shadow_Policy_Summary_Text : STRING(160);
"""

if "Sensor_Shadow_CO_Healthy" not in text:
    if anchor not in text:
        raise SystemExit("Aggregation anchor not found in ST_System_Diagnostics.dut")
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

block = """// === SHADOW POLICY STATS SUMMARY ===
GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Healthy :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Fallback_Count <=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Recovery_Count;

GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Healthy :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Fallback_Count <=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Recovery_Count;

GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Healthy :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Fallback_Count <=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Recovery_Count;

// dominant channel by fallback count
GVL_STATUS.G_Diagnostics.Sensor_Shadow_Dominant_Channel := 'CO';

IF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Fallback_Count >
   GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Fallback_Count THEN
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Dominant_Channel := 'Methane';
END_IF;

IF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Fallback_Count >
   GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Fallback_Count AND
   GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Fallback_Count >
   GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Fallback_Count THEN
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Dominant_Channel := 'Smoke';
END_IF;

IF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Fallback_Count = 0 THEN
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Policy_Summary_Text := 'No shadow fallback events';
ELSIF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Fallback_Count =
      GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Recovery_Count THEN
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Policy_Summary_Text := 'Shadow policy balanced';
ELSIF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Fallback_Count >
      GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Recovery_Count THEN
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Policy_Summary_Text := 'Fallbacks exceed recoveries';
ELSE
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Policy_Summary_Text := 'Recoveries exceed fallbacks';
END_IF;

"""

if "// === SHADOW POLICY STATS SUMMARY ===" not in text:
    text = text.replace(marker, block + marker, 1)

prg.write_text(text, encoding="utf-8")
print("OK: added shadow policy stats summary")
