from pathlib import Path

p = Path("FB_Heating_System_Manager.st")
text = p.read_text(encoding="utf-8")

start_inj = text.find("// --- HEATING TARGET INJECTION ---")
start_adapt = text.find("// --- MULTI-ZONE ADAPTIVE CORRECTION ---")
zone_anchor = text.find("// 2. Индивидуальное управление зонами отопления")

if start_inj == -1:
    raise SystemExit("HEATING TARGET INJECTION block not found")
if start_adapt == -1:
    raise SystemExit("MULTI-ZONE ADAPTIVE CORRECTION block not found")
if zone_anchor == -1:
    raise SystemExit("Zone control anchor not found")

# remove everything from first target injection block up to zone control anchor
text = text[:start_inj] + text[zone_anchor:]

zone_anchor = text.find("// 2. Индивидуальное управление зонами отопления")
if zone_anchor == -1:
    raise SystemExit("Zone control anchor missing after cleanup")

block = """// --- HEATING TARGET INJECTION ---
// Global arbitration target is applied after base policy calculation.
IF GVL_STATE.G_Target_Temperature > 0.0 THEN
    L_Target_Supply_Temp := GVL_STATE.G_Target_Temperature;
END_IF;

// --- MULTI-ZONE ADAPTIVE CORRECTION ---
// Final adaptive refinement layer.
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

        IF VI_Zone_Configs[L_Adaptive_Zone_i].zone >= 1 AND VI_Zone_Configs[L_Adaptive_Zone_i].zone <= 4 THEN
            L_Adaptive_Weight := L_Adaptive_Weight * 1.2;
        ELSIF VI_Zone_Configs[L_Adaptive_Zone_i].zone >= 9 THEN
            L_Adaptive_Weight := L_Adaptive_Weight * 0.7;
        END_IF;

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

"""

text = text[:zone_anchor] + block + text[zone_anchor:]

p.write_text(text, encoding="utf-8")
print("OK: precise heating finalization applied")
