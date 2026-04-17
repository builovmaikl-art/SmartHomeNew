from pathlib import Path
import re

path = Path("FB_Alarm_Manager.st")
text = path.read_text(encoding="utf-8")

# 1) Repair damaged VAR block tail
bad_var = (
    "    L_Event_Pulse_Latched : BOOL;    L_Alarm_First_Warning : STRING(255);\n"
    "    L_Alarm_First_Warning_Latched : BOOL;    L_Alarm_Shadow_First_Mismatch : INT;    "
    "L_Alarm_Using_Legacy_Fallback : BOOL;    "
    "L_History_V2_Buffer_Shadow : ARRAY[1..GVL_CONSTANTS.C_MAX_HISTORY_RECORDS] OF ST_History_Event_V2;END_VAR\n"
)
good_var = (
    "    L_Event_Pulse_Latched : BOOL;\n"
    "END_VAR\n"
)
if bad_var in text:
    text = text.replace(bad_var, good_var, 1)

# 2) Repair damaged init area
bad_init = (
    "VO_Event_Pulse := FALSE;\n"
    "VO_Event_Code := 0;\n"
    "VO_Event_Value := 0.0;L_Alarm_First_Warning := '';\n"
    "L_Alarm_First_Warning_Latched := FALSE;L_Alarm_Shadow_First_Mismatch := 0;// 1. Детекция новых тревог (антидребезг + передний фронт)\n"
)
good_init = (
    "VO_Event_Pulse := FALSE;\n"
    "VO_Event_Code := 0;\n"
    "VO_Event_Value := 0.0;\n\n"
    "// 1. Детекция новых тревог (антидребезг + передний фронт)\n"
)
if bad_init in text:
    text = text.replace(bad_init, good_init, 1)

# 3) Remove broken no-op alarm v2 scaffold block
text = re.sub(
    r"\n// Staging integration: Alarm V2 core is currently a no-op\.\n"
    r"// Inlined from FB_Alarm_V2_Core\n"
    r"IF L_Alarm_V2_Switch_Enabled AND L_Alarm_V2_Path_Ready THEN\n"
    r"    // No runtime mutation in current V2 core\.\n"
    r"END_IF;\n",
    "\n",
    text,
    count=1,
)

# 4) Repair broken compatibility/scaffold fragment inside pending loop
broken_loop_fragment = (
    "    // Inlined from FB_Alarm_Compatibility_Package:\n"
    "    // current compatibility path is a no-op roundtrip with VO_OK always TRUE.\n"
    "    // Phase 4 scaffold: optional Alarm V2 switch point.\n"
    "    // Current state: always remain on legacy behavior.\n"
    "    // Future state: when Alarm V2 path is implemented and validated,\n"
    "    // this block becomes the controlled branch point.\n"
    "    IF L_Alarm_V2_Switch_Enabled AND L_Alarm_V2_Path_Ready THEN        // Guarded V2 pipeline is allowed by shadow validation.\n"
    "        // Current runtime logic still keeps legacy action flow authoritative until next package.\n"
    "    ELSE    END_IF;\n"
)
replacement_loop_fragment = (
    "    // Inlined from FB_Alarm_Compatibility_Package:\n"
    "    // current compatibility path is a no-op roundtrip with VO_OK always TRUE.\n"
)
if broken_loop_fragment in text:
    text = text.replace(broken_loop_fragment, replacement_loop_fragment, 1)

# 5) Remove stray broken block between END_FOR and section 3
text = text.replace("\n\n        END_IF;\n    END_FOR;\nEND_IF;\n\n// 3. Обновление статуса существующих тревог (ушли ли они?)\n",
                    "\n\n// 3. Обновление статуса существующих тревог (ушли ли они?)\n", 1)

# 6) Remove broken blackbox/shadow leftovers before statistics section
text = re.sub(
    r"\n\nIF \(L_BlackBox_V2_Snapshot_Shadow\.Gas_Alarm <> VI_Gas_Alarm\)\n"
    r"   OR \(L_BlackBox_V2_Snapshot_Shadow\.Fire_Alarm <> VI_Fire_Alarm\)\n"
    r"   OR \(L_BlackBox_V2_Snapshot_Shadow\.Flood_Alarm <> VI_Flood_Alarm\)\n"
    r"   OR \(L_BlackBox_V2_Snapshot_Shadow\.First_Fault_Type <> TO_BYTE\(VI_First_Fault_Type\)\)\n"
    r"   OR \(L_BlackBox_V2_Snapshot_Shadow\.First_Fault_Source <> TO_BYTE\(VI_First_Fault_Source\)\) THENEND_IF;\n\n"
    r"ELSEEND_IF;\n",
    "\n",
    text,
    count=1,
)

# 7) Remove any remaining obviously dead declarations that may have survived corruption
for line in [
    "    L_Alarm_First_Warning : STRING(255);\n",
    "    L_Alarm_First_Warning_Latched : BOOL;\n",
    "    L_Alarm_Shadow_First_Mismatch : INT;\n",
    "    L_Alarm_Using_Legacy_Fallback : BOOL;\n",
    "    L_History_V2_Buffer_Shadow : ARRAY[1..GVL_CONSTANTS.C_MAX_HISTORY_RECORDS] OF ST_History_Event_V2;\n",
    "    L_BlackBox_V2_Snapshot_Shadow : ST_BlackBox_Snapshot_V2;\n",
]:
    text = text.replace(line, "")

# 8) Remove remaining references to dead internal scaffold controls if they survived
text = re.sub(r"^\s*IF L_Alarm_V2_Switch_Enabled AND L_Alarm_V2_Path_Ready THEN\s*$\n", "", text, flags=re.M)
text = re.sub(r"^\s*L_Alarm_Using_Legacy_Fallback := FALSE;\s*$\n", "", text, flags=re.M)
text = re.sub(r"^\s*L_Alarm_Using_Legacy_Fallback := TRUE;\s*$\n", "", text, flags=re.M)

path.write_text(text, encoding="utf-8")
print("OK: repaired FB_Alarm_Manager.st structure after bad cleanup")
