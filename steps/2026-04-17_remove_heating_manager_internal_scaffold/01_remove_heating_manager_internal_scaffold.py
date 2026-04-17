from pathlib import Path
import re

path = Path("FB_Heating_System_Manager.st")
text = path.read_text(encoding="utf-8")

# 1. Remove VAR declarations
for old in [
    "    L_Heating_V2_Command_V2 : ST_Heating_Command_V2;\n",
    "    L_Heating_V2_State_V2 : ST_Heating_State_V2;\n",
    "    L_Heating_V2_Shadow_Diff_Found : BOOL;\n",
    "    L_Heating_V2_Switch_Enabled : BOOL;\n",
    "    L_Heating_V2_Path_Ready : BOOL;\n",
    "    L_Heating_Using_Legacy_Fallback : BOOL;\n",
]:
    text = text.replace(old, "")

# 2. Remove init lines
for old in [
    "L_Heating_V2_Shadow_Diff_Found := FALSE;\n",
    "L_Heating_V2_Switch_Enabled := TRUE;\n",
    "L_Heating_V2_Path_Ready := FALSE;\n",
    "L_Heating_Using_Legacy_Fallback := TRUE;\n",
]:
    text = text.replace(old, "")

# 3. Remove scaffold block from exact start anchor to END_FUNCTION_BLOCK
pattern = re.compile(
    r"\n// ========================================\n"
    r"// Heating V2 shadow execution \(phase2\)\n"
    r"// Inlined from FB_Heating_V2_Staging\n"
    r"// ========================================\n"
    r".*?"
    r"\nEND_FUNCTION_BLOCK",
    re.S,
)

m = pattern.search(text)
if not m:
    raise SystemExit("Heating scaffold section not found by exact tail pattern")

text = text[:m.start()] + "\nEND_FUNCTION_BLOCK" + text[m.end():]

path.write_text(text, encoding="utf-8")
print("OK: removed internal scaffold from FB_Heating_System_Manager.st")
