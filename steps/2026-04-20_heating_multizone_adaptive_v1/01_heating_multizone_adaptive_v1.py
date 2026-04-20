from pathlib import Path

p = Path("FB_Heating_System_Manager.st")
text = p.read_text(encoding="utf-8")

block = """

// --- MULTI-ZONE ADAPTIVE CORRECTION ---
VAR
    L_Max_Delta : REAL := 0.0;
    L_Delta : REAL := 0.0;
    i : INT;
END_VAR

L_Max_Delta := 0.0;

FOR i := 1 TO 32 DO
    IF VI_Zone_Configs[i].Enabled THEN
        L_Delta := VI_Zone_Configs[i].Target_Temperature - VI_Room_Temps[i];
        IF L_Delta > L_Max_Delta THEN
            L_Max_Delta := L_Delta;
        END_IF;
    END_IF;
END_FOR;

// apply correction
IF L_Max_Delta > 1.0 THEN
    L_Target_Supply_Temp := L_Target_Supply_Temp + 2.0;
ELSIF L_Max_Delta < -1.0 THEN
    L_Target_Supply_Temp := L_Target_Supply_Temp - 2.0;
END_IF;

"""

if "MULTI-ZONE ADAPTIVE CORRECTION" not in text:
    anchor = "// 2. Расчет целевой температуры подачи теплоносителя"
    if anchor not in text:
        raise SystemExit("Anchor not found in Heating Manager")
    text = text.replace(anchor, block + "\n" + anchor, 1)

p.write_text(text, encoding="utf-8")

print("OK: multi-zone adaptive v1 added")
