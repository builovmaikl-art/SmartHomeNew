from pathlib import Path

# ------------------------------------------------------------
# 1) Extend ST_System_Diagnostics.dut (isolated rate layer)
# ------------------------------------------------------------
dut = Path("ST_System_Diagnostics.dut")
text = dut.read_text(encoding="utf-8")

anchor = "Sensor_Shadow_Recent_Activity_Text : STRING(160);"

insert = """Sensor_Shadow_Recent_Activity_Text : STRING(160);

    // === RATE METRICS (ISOLATED) ===
    Sensor_Shadow_Rate_Fallback_Per_Hour : REAL;
    Sensor_Shadow_Rate_Recovery_Per_Hour : REAL;

    Sensor_Shadow_CO_Rate_Fallback_Per_Hour : REAL;
    Sensor_Shadow_Methane_Rate_Fallback_Per_Hour : REAL;
    Sensor_Shadow_Smoke_Rate_Fallback_Per_Hour : REAL;

    Sensor_Shadow_Rate_High_Activity : BOOL;
    Sensor_Shadow_Rate_Summary_Text : STRING(160);
"""

if "Sensor_Shadow_Rate_Fallback_Per_Hour" not in text:
    if anchor not in text:
        raise SystemExit("Recent activity anchor not found")
    text = text.replace(anchor, insert, 1)

dut.write_text(text, encoding="utf-8")

# ------------------------------------------------------------
# 2) Patch PRG_System (rate computation block)
# ------------------------------------------------------------
prg = Path("PRG_System.st")
text = prg.read_text(encoding="utf-8")

marker = "// === LIFETIME UPDATE ==="
if marker not in text:
    raise SystemExit("LIFETIME marker not found")

block = """// === SHADOW POLICY RATE METRICS ===
VAR
    L_Window_Hours : REAL;
END_VAR

IF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Recent_Window_MS > 0 THEN
    L_Window_Hours :=
        REAL(GVL_STATUS.G_Diagnostics.Sensor_Shadow_Recent_Window_MS) / 3600000.0;
ELSE
    L_Window_Hours := 1.0;
END_IF;

// total rates
GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Fallback_Per_Hour :=
    REAL(GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Fallback_Count) / L_Window_Hours;

GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Recovery_Per_Hour :=
    REAL(GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Recovery_Count) / L_Window_Hours;

// per-channel fallback rates
GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Rate_Fallback_Per_Hour :=
    REAL(GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Fallback_Count) / L_Window_Hours;

GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Rate_Fallback_Per_Hour :=
    REAL(GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Fallback_Count) / L_Window_Hours;

GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Rate_Fallback_Per_Hour :=
    REAL(GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Fallback_Count) / L_Window_Hours;

// simple activity classification
GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_High_Activity :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Fallback_Per_Hour > 10.0;

IF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_High_Activity THEN
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Summary_Text := 'High shadow fallback rate';
ELSIF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Fallback_Per_Hour > 0.0 THEN
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Summary_Text := 'Moderate shadow activity';
ELSE
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Summary_Text := 'No shadow fallback activity';
END_IF;

"""

if "// === SHADOW POLICY RATE METRICS ===" not in text:
    text = text.replace(marker, block + marker, 1)

prg.write_text(text, encoding="utf-8")
print("OK: added isolated shadow policy rate metrics")
