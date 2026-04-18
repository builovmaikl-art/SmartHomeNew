from pathlib import Path

# ------------------------------------------------------------
# 1) Extend GVL_GATEWAY (если нет нужных полей)
# ------------------------------------------------------------
gvl = Path("GVL_GATEWAY.gvl")
text = gvl.read_text(encoding="utf-8")

anchor = "END_VAR"

insert = """    // === SHADOW POLICY EXPORT ===
    G_Shadow_Alert_Active : BOOL;
    G_Shadow_Dominant_Channel : STRING(32);
    G_Shadow_Policy_Summary_Text : STRING(160);
    G_Shadow_Recent_Activity_Text : STRING(160);
    G_Shadow_Rate_Summary_Text : STRING(160);
    G_Shadow_Total_Fallback_Count : UDINT;
    G_Shadow_Total_Recovery_Count : UDINT;

"""

if "G_Shadow_Alert_Active" not in text:
    text = text.replace(anchor, insert + "END_VAR", 1)

gvl.write_text(text, encoding="utf-8")

# ------------------------------------------------------------
# 2) Bridge in PRG_System
# ------------------------------------------------------------
prg = Path("PRG_System.st")
text = prg.read_text(encoding="utf-8")

marker = "// === EXTERNAL MONITORING EXPORT ==="
if marker not in text:
    raise SystemExit("External export block not found")

block = """// === GATEWAY SHADOW EXPORT BRIDGE ===
GVL_GATEWAY.G_Shadow_Alert_Active :=
    GVL_External_Monitoring.G_Shadow_Any_Alert_Active;

GVL_GATEWAY.G_Shadow_Dominant_Channel :=
    GVL_External_Monitoring.G_Shadow_Dominant_Channel;

GVL_GATEWAY.G_Shadow_Policy_Summary_Text :=
    GVL_External_Monitoring.G_Shadow_Policy_Summary_Text;

GVL_GATEWAY.G_Shadow_Recent_Activity_Text :=
    GVL_External_Monitoring.G_Shadow_Recent_Activity_Text;

GVL_GATEWAY.G_Shadow_Rate_Summary_Text :=
    GVL_External_Monitoring.G_Shadow_Rate_Summary_Text;

GVL_GATEWAY.G_Shadow_Total_Fallback_Count :=
    GVL_External_Monitoring.G_Shadow_Total_Fallback_Count;

GVL_GATEWAY.G_Shadow_Total_Recovery_Count :=
    GVL_External_Monitoring.G_Shadow_Total_Recovery_Count;

"""

if "// === GATEWAY SHADOW EXPORT BRIDGE ===" not in text:
    text = text.replace(marker, marker + "\n" + block, 1)

prg.write_text(text, encoding="utf-8")
print("OK: added gateway shadow export bridge")
