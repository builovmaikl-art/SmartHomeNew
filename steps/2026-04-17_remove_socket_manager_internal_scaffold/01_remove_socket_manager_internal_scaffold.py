from pathlib import Path
import re

path = Path("FB_Socket_Manager.st")
text = path.read_text(encoding="utf-8")

# 1. Remove VAR declarations
for old in [
    "    L_Socket_V2_Command_Shadow : ST_Socket_Command_V2;\n",
    "    L_Socket_V2_State_Shadow : ST_Socket_State_V2;\n",
    "    L_Socket_V2_Shadow_Diff_Found : BOOL;\n",
    "    L_Socket_V2_Switch_Enabled : BOOL;\n",
    "    L_Socket_V2_Path_Ready : BOOL;\n",
    "    L_Socket_Using_Legacy_Fallback : BOOL;\n",
]:
    text = text.replace(old, "")

# 2. Remove init lines
for old in [
    "L_Socket_V2_Shadow_Diff_Found := FALSE;\n",
    "L_Socket_V2_Switch_Enabled := TRUE;\n",
    "L_Socket_V2_Path_Ready := FALSE;\n",
    "L_Socket_Using_Legacy_Fallback := TRUE;\n",
]:
    text = text.replace(old, "")

# 3. Remove trailing scaffold section by anchors
pattern = re.compile(
    r"\n// ========================================\n"
    r"// Socket V2 shadow execution \(phase2\)\n"
    r"// Inlined from FB_Socket_V2_Staging\n"
    r"// ========================================\n"
    r".*?"
    r"END_IF;\n"
    r"\nEND_FUNCTION_BLOCK",
    re.S,
)

m = pattern.search(text)
if not m:
    raise SystemExit("Socket scaffold section not found by anchor pattern")

replacement = "\nEND_FUNCTION_BLOCK"
text = text[:m.start()] + replacement + text[m.end():]

path.write_text(text, encoding="utf-8")
print("OK: removed internal scaffold from FB_Socket_Manager.st")
