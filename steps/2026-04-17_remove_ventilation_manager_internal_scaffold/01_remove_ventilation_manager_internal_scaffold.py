from pathlib import Path
import re

path = Path("FB_Ventilation_System_Manager.st")
text = path.read_text(encoding="utf-8")

# 1. Remove VAR declarations
for old in [
    "    L_Vent_Command_Shadow : ST_Ventilation_Command_V2;\n",
    "    L_Vent_State_Shadow : ST_Ventilation_State_V2;\n",
    "    L_Vent_V2_Shadow_Diff_Found : BOOL;\n",
    "    L_Vent_V2_Switch_Enabled : BOOL;\n",
    "    L_Vent_V2_Path_Ready : BOOL;\n",
    "    L_Vent_Using_Legacy_Fallback : BOOL;\n",
]:
    text = text.replace(old, "")

# 2. Remove init lines
for old in [
    "L_Vent_V2_Shadow_Diff_Found := FALSE;\n",
    "L_Vent_V2_Switch_Enabled := TRUE;\n",
    "L_Vent_V2_Path_Ready := FALSE;\n",
    "L_Vent_Using_Legacy_Fallback := TRUE;\n",
]:
    text = text.replace(old, "")

# 3. Remove scaffold tail block by anchors
pattern = re.compile(
    r"\n// Ventilation V2 shadow runtime integration \(diagnostic only\)\n"
    r"// Inlined from FB_Ventilation_V2_Staging\n"
    r".*?"
    r"END_IF;\n"
    r"\n// 4\. Формирование статусного сообщения\n",
    re.S,
)

m = pattern.search(text)
if not m:
    raise SystemExit("Ventilation scaffold section not found by anchor pattern")

replacement = "\n// 4. Формирование статусного сообщения\n"
text = text[:m.start()] + replacement + text[m.end():]

path.write_text(text, encoding="utf-8")
print("OK: removed internal scaffold from FB_Ventilation_System_Manager.st")
