from pathlib import Path

# ------------------------------------------------------------
# 1) Create GVL_External_Monitoring.gvl if missing
# ------------------------------------------------------------
gvl_path = Path("GVL_External_Monitoring.gvl")
if not gvl_path.exists():
    gvl_path.write_text(
"""VAR_GLOBAL
    // === EXTERNAL SHADOW POLICY CONTRACT ===
    G_Shadow_Any_Alert_Active : BOOL;
    G_Shadow_CO_Active : BOOL;
    G_Shadow_Methane_Active : BOOL;
    G_Shadow_Smoke_Active : BOOL;

    G_Shadow_CO_Healthy : BOOL;
    G_Shadow_Methane_Healthy : BOOL;
    G_Shadow_Smoke_Healthy : BOOL;

    G_Shadow_Dominant_Channel : STRING(32);
    G_Shadow_Policy_Summary_Text : STRING(160);
    G_Shadow_Recent_Activity_Text : STRING(160);
    G_Shadow_Rate_Summary_Text : STRING(160);
    G_Shadow_Rate_Alert_Text : STRING(160);

    G_Shadow_Total_Fallback_Count : UDINT;
    G_Shadow_Total_Recovery_Count : UDINT;

    G_Shadow_Rate_Fallback_Per_Hour : REAL;
    G_Shadow_Rate_Recovery_Per_Hour : REAL;

    G_Shadow_Rate_Alert_Active : BOOL;
END_VAR
""",
        encoding="utf-8"
    )
    print("OK: created GVL_External_Monitoring.gvl")
else:
    print("OK: GVL_External_Monitoring.gvl already exists")

# ------------------------------------------------------------
# 2) Patch PRG_System.st with export block
# ------------------------------------------------------------
prg = Path("PRG_System.st")
text = prg.read_text(encoding="utf-8")

marker = "// === LIFETIME UPDATE ==="
if marker not in text:
    raise SystemExit("LIFETIME marker not found in PRG_System.st")

block = """// === EXTERNAL MONITORING EXPORT ===
GVL_External_Monitoring.G_Shadow_Any_Alert_Active :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Alert_Active;

GVL_External_Monitoring.G_Shadow_CO_Active :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Active;
GVL_External_Monitoring.G_Shadow_Methane_Active :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Active;
GVL_External_Monitoring.G_Shadow_Smoke_Active :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Active;

GVL_External_Monitoring.G_Shadow_CO_Healthy :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Healthy;
GVL_External_Monitoring.G_Shadow_Methane_Healthy :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Healthy;
GVL_External_Monitoring.G_Shadow_Smoke_Healthy :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Healthy;

GVL_External_Monitoring.G_Shadow_Dominant_Channel :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Dominant_Channel;
GVL_External_Monitoring.G_Shadow_Policy_Summary_Text :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Policy_Summary_Text;
GVL_External_Monitoring.G_Shadow_Recent_Activity_Text :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Recent_Activity_Text;
GVL_External_Monitoring.G_Shadow_Rate_Summary_Text :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Summary_Text;
GVL_External_Monitoring.G_Shadow_Rate_Alert_Text :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Alert_Text;

GVL_External_Monitoring.G_Shadow_Total_Fallback_Count :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Fallback_Count;
GVL_External_Monitoring.G_Shadow_Total_Recovery_Count :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Recovery_Count;

GVL_External_Monitoring.G_Shadow_Rate_Fallback_Per_Hour :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Fallback_Per_Hour;
GVL_External_Monitoring.G_Shadow_Rate_Recovery_Per_Hour :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Recovery_Per_Hour;

GVL_External_Monitoring.G_Shadow_Rate_Alert_Active :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Alert_Active;

"""

if "// === EXTERNAL MONITORING EXPORT ===" not in text:
    text = text.replace(marker, block + marker, 1)

prg.write_text(text, encoding="utf-8")
print("OK: added external monitoring export block to PRG_System.st")
