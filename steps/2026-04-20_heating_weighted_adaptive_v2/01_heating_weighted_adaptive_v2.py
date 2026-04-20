from pathlib import Path
import re

p = Path("FB_Heating_System_Manager.st")
text = p.read_text(encoding="utf-8")

# -------------------------------------------------
# 1. Extend main VAR section with weighted-adaptive vars
# -------------------------------------------------
var_anchor = """    L_Adaptive_Max_Delta : REAL;
    L_Adaptive_Delta : REAL;
    L_Adaptive_Zone_i : INT;
END_VAR
"""

var_replacement = """    L_Adaptive_Max_Delta : REAL;
    L_Adaptive_Delta : REAL;
    L_Adaptive_Zone_i : INT;
    L_Adaptive_Weighted_Sum : REAL;
    L_Adaptive_Weight_Total : REAL;
    L_Adaptive_Effective_Delta : REAL;
    L_Adaptive_Weight : REAL;
    L_Adaptive_Correction : REAL;
END_VAR
"""

if "L_Adaptive_Weighted_Sum" not in text:
    if var_anchor not in text:
        raise SystemExit("Adaptive VAR anchor not found")
    text = text.replace(var_anchor, var_replacement, 1)

# -------------------------------------------------
# 2. Replace current adaptive block with weighted v2
# -------------------------------------------------
pattern = r"// --- MULTI-ZONE ADAPTIVE CORRECTION ---.*?// apply correction.*?END_IF;"
replacement = """// --- MULTI-ZONE ADAPTIVE CORRECTION ---
L_Adaptive_Max_Delta := 0.0;
L_Adaptive_Weighted_Sum := 0.0;
L_Adaptive_Weight_Total := 0.0;
L_Adaptive_Effective_Delta := 0.0;
L_Adaptive_Correction := 0.0;

FOR L_Adaptive_Zone_i := 1 TO 8 DO
    IF VI_Zone_Configs[L_Adaptive_Zone_i].zone >= 1 AND VI_Zone_Configs[L_Adaptive_Zone_i].zone <= 16 THEN
        L_Adaptive_Delta :=
            VI_Zone_Configs[L_Adaptive_Zone_i].design_temp -
            VI_Room_Temps[VI_Zone_Configs[L_Adaptive_Zone_i].zone];

        IF L_Adaptive_Delta > L_Adaptive_Max_Delta THEN
            L_Adaptive_Max_Delta := L_Adaptive_Delta;
        END_IF;

        // Weight by control strategy:
        // air-controlled circuits influence supply stronger than floor-controlled circuits
        CASE VI_Zone_Configs[L_Adaptive_Zone_i].control_type OF
            1, 2:
                L_Adaptive_Weight := 1.0;
            ELSE
                L_Adaptive_Weight := 0.6;
        END_CASE;

        // Only heating demand contributes positively here.
        // Strong overheating should still be allowed to soften the target via weighted average.
        L_Adaptive_Weighted_Sum := L_Adaptive_Weighted_Sum + (L_Adaptive_Delta * L_Adaptive_Weight);
        L_Adaptive_Weight_Total := L_Adaptive_Weight_Total + L_Adaptive_Weight;
    END_IF;
END_FOR;

IF L_Adaptive_Weight_Total > 0.0 THEN
    L_Adaptive_Effective_Delta := L_Adaptive_Weighted_Sum / L_Adaptive_Weight_Total;
END_IF;

// Conservative correction layer:
// 1) average demand drives the main correction
// 2) single-zone cold outlier can still boost support if it is significant
IF L_Adaptive_Effective_Delta > 1.5 THEN
    L_Adaptive_Correction := 2.0;
ELSIF L_Adaptive_Effective_Delta > 0.7 THEN
    L_Adaptive_Correction := 1.0;
ELSIF L_Adaptive_Effective_Delta < -1.5 THEN
    L_Adaptive_Correction := -2.0;
ELSIF L_Adaptive_Effective_Delta < -0.7 THEN
    L_Adaptive_Correction := -1.0;
ELSE
    L_Adaptive_Correction := 0.0;
END_IF;

// protect against one very cold room being fully diluted by the average
IF L_Adaptive_Max_Delta > 2.5 THEN
    IF L_Adaptive_Correction < 2.0 THEN
        L_Adaptive_Correction := 2.0;
    END_IF;
END_IF;

L_Target_Supply_Temp := L_Target_Supply_Temp + L_Adaptive_Correction;

// final clamp for adaptive influence only
IF L_Target_Supply_Temp < 20.0 THEN
    L_Target_Supply_Temp := 20.0;
ELSIF L_Target_Supply_Temp > 45.0 THEN
    L_Target_Supply_Temp := 45.0;
END_IF;"""

new_text, count = re.subn(pattern, replacement, text, flags=re.S)
if count != 1:
    raise SystemExit(f"Expected exactly 1 adaptive block replacement, got {count}")

text = new_text
p.write_text(text, encoding="utf-8")
print("OK: weighted adaptive heating v2 applied")
