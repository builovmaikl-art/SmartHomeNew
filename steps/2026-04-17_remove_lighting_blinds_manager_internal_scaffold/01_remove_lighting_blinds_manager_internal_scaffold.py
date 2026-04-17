from pathlib import Path
import re

path = Path("FB_Lighting_Blinds_Manager.st")
text = path.read_text(encoding="utf-8")

# 1. Remove VAR declarations
for old in [
    "    L_Blinds_V2_Command_Shadow : ST_Blinds_Command_V2;\n",
    "    L_Blinds_V2_State_Shadow : ST_Blinds_State_V2;\n",
    "    L_Blinds_V2_Shadow_Diff_Found : BOOL;\n",
    "    L_Blinds_V2_Switch_Enabled : BOOL;\n",
    "    L_Blinds_V2_Path_Ready : BOOL;\n",
    "    L_Blinds_Using_Legacy_Fallback : BOOL;\n",
    "    L_Lighting_V2_Command_Shadow : ST_Lighting_Command_V2;\n",
    "    L_Lighting_V2_State_Shadow : ST_Lighting_State_V2;\n",
    "    L_Lighting_V2_Shadow_Diff_Found : BOOL;\n",
    "    L_Lighting_V2_Switch_Enabled : BOOL;\n",
    "    L_Lighting_V2_Path_Ready : BOOL;\n",
    "    L_Lighting_Using_Legacy_Fallback : BOOL;\n",
]:
    text = text.replace(old, "")

# 2. Remove init lines
for old in [
    "L_Lighting_V2_Shadow_Diff_Found := FALSE;\n",
    "L_Blinds_V2_Shadow_Diff_Found := FALSE;\n",
    "L_Blinds_V2_Switch_Enabled := TRUE;\n",
    "L_Blinds_V2_Path_Ready := FALSE;\n",
    "L_Blinds_Using_Legacy_Fallback := TRUE;\n",
    "L_Lighting_V2_Switch_Enabled := TRUE;\n",
    "L_Lighting_V2_Path_Ready := FALSE;\n",
    "L_Lighting_Using_Legacy_Fallback := TRUE;\n",
]:
    text = text.replace(old, "")

# 3. Remove lighting scaffold block
lighting_pattern = re.compile(
    r"\n// ========================================\n"
    r"// Lighting V2 shadow execution \(phase2\)\n"
    r"// Inlined from FB_Lighting_V2_Staging\n"
    r"// ========================================\n"
    r".*?"
    r"END_IF;\n"
    r"\n\n\n",
    re.S,
)
m = lighting_pattern.search(text)
if not m:
    raise SystemExit("Lighting scaffold block not found")
text = text[:m.start()] + "\n\n" + text[m.end():]

# 4. Remove blinds scaffold block up to END_FUNCTION_BLOCK
blinds_pattern = re.compile(
    r"\n// ========================================\n"
    r"// Blinds V2 shadow execution \(phase2\)\n"
    r"// Inlined from FB_Blinds_V2_Staging\n"
    r"// ========================================\n"
    r".*?"
    r"END_IF;\n"
    r"\nEND_FUNCTION_BLOCK",
    re.S,
)
m = blinds_pattern.search(text)
if not m:
    raise SystemExit("Blinds scaffold block not found")
text = text[:m.start()] + "\nEND_FUNCTION_BLOCK" + text[m.end():]

path.write_text(text, encoding="utf-8")
print("OK: removed internal scaffold from FB_Lighting_Blinds_Manager.st")
