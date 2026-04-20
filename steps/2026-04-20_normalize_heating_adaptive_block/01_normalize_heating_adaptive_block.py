from pathlib import Path
import re

p = Path("FB_Heating_System_Manager.st")
text = p.read_text(encoding="utf-8")

# 1. Add variables to the main VAR section if missing
var_anchor = "    L_Any_Subsystem_Degraded : BOOL;\nEND_VAR\n"
var_insert = """    L_Any_Subsystem_Degraded : BOOL;
    L_Adaptive_Max_Delta : REAL;
    L_Adaptive_Delta : REAL;
    L_Adaptive_Zone_i : INT;
END_VAR
"""

if "L_Adaptive_Max_Delta" not in text or "L_Adaptive_Delta" not in text or "L_Adaptive_Zone_i" not in text:
    if var_anchor not in text:
        raise SystemExit("Main VAR anchor not found in FB_Heating_System_Manager.st")
    text = text.replace(var_anchor, var_insert, 1)

# 2. Replace the adaptive block with normalized implementation (no inner VAR)
pattern = r"\n// --- MULTI-ZONE ADAPTIVE CORRECTION ---.*?// 2\. Расчет целевой температуры подачи теплоносителя"
replacement = """
// --- MULTI-ZONE ADAPTIVE CORRECTION ---
L_Adaptive_Max_Delta := 0.0;

FOR L_Adaptive_Zone_i := 1 TO 8 DO
    IF VI_Zone_Configs[L_Adaptive_Zone_i].enabled THEN
        IF VI_Zone_Configs[L_Adaptive_Zone_i].zone >= 1 AND VI_Zone_Configs[L_Adaptive_Zone_i].zone <= 16 THEN
            L_Adaptive_Delta :=
                VI_Zone_Configs[L_Adaptive_Zone_i].design_temp -
                VI_Room_Temps[VI_Zone_Configs[L_Adaptive_Zone_i].zone];

            IF L_Adaptive_Delta > L_Adaptive_Max_Delta THEN
                L_Adaptive_Max_Delta := L_Adaptive_Delta;
            END_IF;
        END_IF;
    END_IF;
END_FOR;

// apply correction
IF L_Adaptive_Max_Delta > 1.0 THEN
    L_Target_Supply_Temp := L_Target_Supply_Temp + 2.0;
ELSIF L_Adaptive_Max_Delta < -1.0 THEN
    L_Target_Supply_Temp := L_Target_Supply_Temp - 2.0;
END_IF;

// 2. Расчет целевой температуры подачи теплоносителя"""
new_text, count = re.subn(pattern, replacement, text, flags=re.S)
if count == 0:
    raise SystemExit("Adaptive block anchor not found for normalization")
text = new_text

p.write_text(text, encoding="utf-8")
print("OK: normalized adaptive heating block")
