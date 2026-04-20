from pathlib import Path
import re

prg = Path("PRG_Heating.st")
text = prg.read_text(encoding="utf-8")

# -----------------------------
# 1. Ensure state vars exist once
# -----------------------------
if "L_Last_Mode : INT := 0;" not in text:
    raise SystemExit("Expected L_Last_Mode not found")
if "L_Mode_Hold_Timer : FB_System_Timer;" not in text:
    raise SystemExit("Expected L_Mode_Hold_Timer not found")

# -----------------------------
# 2. Remove previously appended heating arbitration/stabilization blocks
# -----------------------------
patterns = [
    r"\n// --- HEATING PRIORITY ARBITRATION ---.*?END_IF;\n",
    r"\n// --- HEATING FINAL TARGET ---.*?END_IF;\n",
    r"\n// --- HEATING STABILIZATION ---.*?END_CASE;\n",
]
for pat in patterns:
    text = re.sub(pat, "\n", text, flags=re.S)

# -----------------------------
# 3. Insert one consolidated block after Heating Arbitration section
# -----------------------------
anchor = "// 9. Управление климатом (Отопление)\n"
block = """// --- CONSOLIDATED HEATING REQUEST / ARBITRATION / STABILIZATION ---
L_Mode_Hold_Timer(
    IN := TRUE,
    PT := T#30s,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

IF L_Mode_Hold_Timer.Q THEN
    IF GVL_STATE.G_Freeze_Request THEN
        L_Last_Mode := 2; // freeze
    ELSIF GVL_STATE.G_Preheat_Request THEN
        L_Last_Mode := 1; // preheat
    ELSE
        L_Last_Mode := 0; // normal
    END_IF;
END_IF;

CASE L_Last_Mode OF
    2:
        GVL_STATE.G_Target_Temperature := 5.0;
    1:
        GVL_STATE.G_Target_Temperature := 22.0;
    ELSE
        GVL_STATE.G_Target_Temperature := 20.0;
END_CASE;

"""
if block not in text:
    if anchor not in text:
        raise SystemExit("Anchor for consolidated heating block not found")
    text = text.replace(anchor, block + anchor, 1)

# -----------------------------
# 4. Make sure manager reads GVL_STATE target only
# -----------------------------
hm = Path("FB_Heating_System_Manager.st")
hm_text = hm.read_text(encoding="utf-8")

hm_text = hm_text.replace("GVL_HEATING_REQUEST.G_Target_Temperature", "GVL_STATE.G_Target_Temperature")
hm_text = hm_text.replace("GVL_HEATING_REQUEST.G_Preheat_Request", "GVL_STATE.G_Preheat_Request")
hm_text = hm_text.replace("GVL_HEATING_REQUEST.G_Freeze_Request", "GVL_STATE.G_Freeze_Request")

# keep only one target injection block
hm_text = re.sub(
    r"\n// --- HEATING TARGET INJECTION ---.*?END_IF;\n",
    "\n// --- HEATING TARGET INJECTION ---\nIF GVL_STATE.G_Target_Temperature > 0.0 THEN\n    L_Target_Supply_Temp := GVL_STATE.G_Target_Temperature;\nEND_IF;\n",
    hm_text,
    flags=re.S
)

# -----------------------------
# 5. Make sure PRG_System writes request flags into GVL_STATE
# -----------------------------
sys = Path("PRG_System.st")
sys_text = sys.read_text(encoding="utf-8")
sys_text = sys_text.replace("GVL_HEATING_REQUEST.G_Preheat_Request", "GVL_STATE.G_Preheat_Request")
sys_text = sys_text.replace("GVL_HEATING_REQUEST.G_Freeze_Request", "GVL_STATE.G_Freeze_Request")
sys_text = sys_text.replace("GVL_HEATING_REQUEST.G_Target_Temperature", "GVL_STATE.G_Target_Temperature")

# remove old free-floating request blocks
sys_text = re.sub(r"\n// --- HEATING REQUEST LAYER ---\n.*?\n", "\n", sys_text, flags=re.S)
sys_text = re.sub(r"\n// --- FREEZE REQUEST ---\n.*?\n", "\n", sys_text, flags=re.S)

# add one consolidated write section after rule engine call
rule_anchor = "END_FOR;\n\n"
write_block = """END_FOR;

// --- HEATING REQUEST WRITE LAYER ---
GVL_STATE.G_Preheat_Request := fbRuleEngine.VO_Preheat_Request;
GVL_STATE.G_Freeze_Request := (GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_FREEZE_PROTECTION);

"""
# place after the rule-action extraction block only once
if "GVL_STATE.G_Preheat_Request := fbRuleEngine.VO_Preheat_Request;" not in sys_text:
    idx = sys_text.find(rule_anchor, sys_text.find("fbRuleEngine("))
    if idx == -1:
        raise SystemExit("Rule engine anchor not found for request write layer")
    sys_text = sys_text[:idx] + write_block + sys_text[idx+len(rule_anchor):]

prg.write_text(text, encoding="utf-8")
hm.write_text(hm_text, encoding="utf-8")
sys.write_text(sys_text, encoding="utf-8")

print("OK: consolidated heating request/arbitration/stabilization into one live layer")
