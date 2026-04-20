from pathlib import Path
import re

p = Path("FB_Heating_System_Manager.st")
text = p.read_text(encoding="utf-8")

# replace delta calculation block only
pattern = r"""L_Adaptive_Delta\s*:=\s*
\s*VI_Zone_Configs\[L_Adaptive_Zone_i\]\.design_temp\s*-\s*
\s*VI_Room_Temps\[VI_Zone_Configs\[L_Adaptive_Zone_i\]\.zone\];"""

replacement = """// select temperature source based on control type
CASE VI_Zone_Configs[L_Adaptive_Zone_i].control_type OF
    0:
        L_Adaptive_Delta :=
            VI_Zone_Configs[L_Adaptive_Zone_i].design_temp -
            VI_Floor_Temps[VI_Zone_Configs[L_Adaptive_Zone_i].zone];
    ELSE
        L_Adaptive_Delta :=
            VI_Zone_Configs[L_Adaptive_Zone_i].design_temp -
            VI_Room_Temps[VI_Zone_Configs[L_Adaptive_Zone_i].zone];
END_CASE;"""

new_text, count = re.subn(pattern, replacement, text)

if count != 1:
    raise SystemExit(f"Expected exactly 1 delta replacement, got {count}")

p.write_text(new_text, encoding="utf-8")

print("OK: floor vs air bias applied")
