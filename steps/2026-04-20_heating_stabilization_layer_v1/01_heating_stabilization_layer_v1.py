from pathlib import Path

prg = Path("PRG_Heating.st")
text = prg.read_text(encoding="utf-8")

# -------------------------
# 1. Add state vars
# -------------------------
vars_block = """
VAR
    L_Last_Mode : INT := 0; // 0=normal,1=preheat,2=freeze
    L_Mode_Hold_Timer : FB_System_Timer;
END_VAR
"""

if "L_Last_Mode" not in text:
    text = text.replace(
        "PROGRAM PRG_Heating",
        "PROGRAM PRG_Heating\n" + vars_block
    )

# -------------------------
# 2. Stabilized arbitration
# -------------------------
block = """

// --- HEATING STABILIZATION ---
L_Mode_Hold_Timer(
    IN := TRUE,
    PT := T#30s,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

IF NOT L_Mode_Hold_Timer.Q THEN
    // hold previous mode
ELSE
    IF GVL_HEATING_REQUEST.G_Freeze_Request THEN
        L_Last_Mode := 2;
    ELSIF GVL_HEATING_REQUEST.G_Preheat_Request THEN
        L_Last_Mode := 1;
    ELSE
        L_Last_Mode := 0;
    END_IF;
END_IF;

// apply stabilized mode
CASE L_Last_Mode OF
    2: GVL_HEATING_REQUEST.G_Target_Temperature := 5.0;
    1: GVL_HEATING_REQUEST.G_Target_Temperature := 22.0;
    ELSE GVL_HEATING_REQUEST.G_Target_Temperature := 20.0;
END_CASE;
"""

if "HEATING STABILIZATION" not in text:
    text += block

prg.write_text(text, encoding="utf-8")

print("OK: heating stabilization layer added")
