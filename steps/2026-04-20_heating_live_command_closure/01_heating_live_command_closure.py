from pathlib import Path
import re

# --- 1. Ensure PRG_System wiring ---
prg_path = Path("PRG_System.st")

if prg_path.exists():
    text = prg_path.read_text()

    # Ensure Heating Manager call uses VI_Command
    if "fbHeatingSystemManager(" in text:

        if "VI_Command :=" not in text:
            text = re.sub(
                r"(fbHeatingSystemManager\s*\()",
                r"\1\n    VI_Command := fbRuleEngine.VO_Heating_Command,",
                text
            )

    prg_path.write_text(text)

# --- 2. Remove legacy direct writes to GVL_HEATING (outside manager) ---
for path in Path(".").rglob("*.st"):
    if "FB_Heating_System_Manager" in str(path):
        continue

    text = path.read_text()

    new_text = re.sub(
        r"GVL_HEATING\.G_Target_Temperature\s*:=",
        "// REMOVED: direct write (use Heating_Command)\n// GVL_HEATING.G_Target_Temperature :=",
        text
    )

    if new_text != text:
        path.write_text(new_text)

# --- 3. Save marker ---
Path("диагностика/heating_live_command_closure_marker.txt").write_text("DONE\n")
