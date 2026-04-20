from pathlib import Path
import re

# 1. Remove broken DUT if present
p = Path("ST_Heating_Command.st")
if p.exists():
    p.unlink()

# 2. Revert FB_Rule_Engine additions
p = Path("FB_Rule_Engine.st")
text = p.read_text(encoding="utf-8")

text = text.replace("    VO_Heating_Command : ST_Heating_Command;\n", "")
text = text.replace("    VO_Preheat_Request : BOOL; // pre-departure heating trigger\n", "    VO_Preheat_Request : BOOL; // pre-departure heating trigger\n")

text = text.replace("""

// --- PREHEAT RULE INSERT ---
IF VO_Preheat_Request THEN
    VO_Heating_Command.Enable := TRUE;
    VO_Heating_Command.Target_Temperature := 22.0;
    VO_Heating_Command.Priority := 10;
END_IF;
""", "")

text = text.replace("""

// --- PREHEAT RULE INSERT ---
IF (GVL_STATUS.G_Departure_Time > 0) THEN
    IF (GVL_STATUS.G_Departure_Time - GVL_STATUS.G_System_Time_MS) < 10800000 THEN
        IF GVL_STATE.G_System_Mode <> MODE_SAFE_STOP THEN
            VO_Preheat_Request := TRUE;
        END_IF;
    END_IF;
END_IF;
""", "")

p.write_text(text, encoding="utf-8")

# 3. Revert FB_Heating_System_Manager additions
p = Path("FB_Heating_System_Manager.st")
text = p.read_text(encoding="utf-8")

text = text.replace("    VI_Command : ST_Heating_Command;\n", "")
text = text.replace("    VI_Preheat_Request : BOOL; // preheat scenario trigger\n", "    VI_Preheat_Request : BOOL; // preheat scenario trigger\n")

text = text.replace("""

// --- PREHEAT HEATING INSERT ---
IF VI_Preheat_Request THEN
    // simple safe preheat: raise target temp slightly
    GVL_HEATING.G_Preheat_Mode := TRUE;
END_IF;
""", "")

text = text.replace("""

// --- HEATING COMMAND INSERT ---
IF VI_Command.Enable THEN
    // apply temperature with priority concept (simplified for now)
    GVL_HEATING.G_Target_Temperature := VI_Command.Target_Temperature;
END_IF;
""", "")

p.write_text(text, encoding="utf-8")

# 4. Revert PRG_Heating broken wiring
p = Path("PRG_Heating.st")
text = p.read_text(encoding="utf-8")
text = text.replace("    VI_Command := fbRuleEngine.VO_Heating_Command,\n", "")
p.write_text(text, encoding="utf-8")

print("OK: rolled back broken heating command layer to last compilable pre-command state")
