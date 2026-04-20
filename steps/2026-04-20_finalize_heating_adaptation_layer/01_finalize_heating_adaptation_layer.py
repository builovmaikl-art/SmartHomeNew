from pathlib import Path
import re

p = Path("FB_Heating_System_Manager.st")
text = p.read_text(encoding="utf-8")

# -------------------------------------------------
# 1. Remove current early target injection block
# -------------------------------------------------
text, count_inj = re.subn(
    r"\n// --- HEATING TARGET INJECTION ---.*?END_IF;\n",
    "\n",
    text,
    count=1,
    flags=re.S
)
if count_inj != 1:
    raise SystemExit(f"Expected 1 HEATING TARGET INJECTION block, got {count_inj}")

# -------------------------------------------------
# 2. Remove current adaptive block
# -------------------------------------------------
text, count_adapt = re.subn(
    r"\n// --- MULTI-ZONE ADAPTIVE CORRECTION ---.*?END_IF;\n\n// 2\. Индивидуальное управление зонами отопления",
    "\n// 2. Индивидуальное управление зонами отопления",
    text,
    count=1,
    flags=re.S
)
if count_adapt != 1:
    raise SystemExit(f"Expected 1 adaptive block replacement, got {count_adapt}")

# -------------------------------------------------
# 3. Insert finalized block after freeze target policy and before zone control
# -------------------------------------------------
anchor = """IF L_Freeze_Mode_Active THEN
    L_Freeze_Target_Supply := LIMIT(20.0, VI_Config.Freeze_Threshold + 2.0, 45.0);
    IF L_Target_Supply_Temp < L_Freeze_Target_Supply THEN
        L_Target_Supply_Temp := L_Freeze_Target_Supply;
    END_IF;
END_IF;

// 2. Индивидуальное управление зонами отопления
"""

final_block = """IF L_Freeze_Mode_Active THEN
    L_Freeze_Target_Supply := LIMIT(20.0, VI_Config.Freeze_Threshold + 2.0, 45.0);
    IF L_Target_Supply_Temp < L_Freeze_Target_Supply THEN
        L_Target_Supply_Temp := L_Freeze_Target_Supply;
    END_IF;
END_IF;

// --- HEATING TARGET INJECTION ---
// Global arbitration target is applied as a lower-layer request before adaptive refinement.
IF GVL_STATE.G_Target_Temperature > 0.0 THEN
    L_Target_Supply_Temp := GVL_STATE.G_Target_Temperature;
END_IF;

// --- MULTI-ZONE ADAPTIVE CORRECTION ---
// Final refinement layer applied AFTER base weather/scenario/freeze policy,
// so it is not overwritten later by the legacy supply calculation.
L_Adaptive_Max_Delta := 0.0;
L_Adaptive_Weighted_Sum := 0.0;
L_Adaptive_Weight_Total := 0.0;
L_Adaptive_Effective_Delta := 0.0;
L_Adaptive_Correction := 0.0;

FOR L_Adaptive_Zone_i := 1 TO 8 DO
    IF VI_Zone_Configs[L_Adaptive_Zone_i].zone >= 1 AND VI_Zone_Configs[L_Adaptive_Zone_i].zone <= 8 THEN
        CASE VI_Zone_Configs[L_Adaptive_Zone_i].control_type OF
            0:
                L_Adaptive_Delta :=
                    VI_Zone_Configs[L_Adaptive_Zone_i].design_temp -
                    VI_Floor_Temps[L_Adaptive_Zone_i];
                L_Adaptive_Weight := 0.6;
            1, 2:
                L_Adaptive_Delta :=
                    VI_Zone_Configs[L_Adaptive_Zone_i].design_temp -
                    VI_Room_Temps[VI_Zone_Configs[L_Adaptive_Zone_i].zone];
                L_Adaptive_Weight := 1.0;
            ELSE
                L_Adaptive_Delta :=
                    VI_Zone_Configs[L_Adaptive_Zone_i].design_temp -
                    VI_Room_Temps[VI_Zone_Configs[L_Adaptive_Zone_i].zone];
                L_Adaptive_Weight := 0.8;
        END_CASE;

        // --- ZONE PRIORITY WEIGHT ---
        IF VI_Zone_Configs[L_Adaptive_Zone_i].zone >= 1 AND VI_Zone_Configs[L_Adaptive_Zone_i].zone <= 4 THEN
            L_Adaptive_Weight := L_Adaptive_Weight * 1.2;
        ELSIF VI_Zone_Configs[L_Adaptive_Zone_i].zone >= 9 THEN
            L_Adaptive_Weight := L_Adaptive_Weight * 0.7;
        END_IF;

        // --- WEIGHT CLAMP ---
        IF L_Adaptive_Weight > 2.0 THEN
            L_Adaptive_Weight := 2.0;
        ELSIF L_Adaptive_Weight < 0.2 THEN
            L_Adaptive_Weight := 0.2;
        END_IF;

        IF L_Adaptive_Delta > L_Adaptive_Max_Delta THEN
            L_Adaptive_Max_Delta := L_Adaptive_Delta;
        END_IF;

        L_Adaptive_Weighted_Sum := L_Adaptive_Weighted_Sum + (L_Adaptive_Delta * L_Adaptive_Weight);
        L_Adaptive_Weight_Total := L_Adaptive_Weight_Total + L_Adaptive_Weight;
    END_IF;
END_FOR;

IF L_Adaptive_Weight_Total > 0.0 THEN
    L_Adaptive_Effective_Delta := L_Adaptive_Weighted_Sum / L_Adaptive_Weight_Total;
END_IF;

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

IF L_Adaptive_Max_Delta > 2.5 AND L_Adaptive_Correction < 2.0 THEN
    L_Adaptive_Correction := 2.0;
END_IF;

L_Target_Supply_Temp := L_Target_Supply_Temp + L_Adaptive_Correction;

IF L_Target_Supply_Temp < 20.0 THEN
    L_Target_Supply_Temp := 20.0;
ELSIF L_Target_Supply_Temp > 45.0 THEN
    L_Target_Supply_Temp := 45.0;
END_IF;

// 2. Индивидуальное управление зонами отопления
"""

if anchor not in text:
    raise SystemExit("Final insertion anchor not found")
text = text.replace(anchor, final_block, 1)

p.write_text(text, encoding="utf-8")
print("OK: finalized heating adaptation layer ordering and normalized adaptive logic")
