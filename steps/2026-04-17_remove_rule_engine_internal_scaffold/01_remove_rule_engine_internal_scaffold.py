from pathlib import Path

path = Path("FB_Rule_Engine.st")
text = path.read_text(encoding="utf-8")

replacements = [
    ("    L_Compat_All_OK : BOOL;\n", ""),
    ("    L_Compat_First_Warning : STRING(255);\n", ""),
    ("    L_Compat_First_Warning_Latched : BOOL;\n", ""),
    ("    L_Shadow_V2_Enabled : BOOL;\n", ""),
    ("    L_Shadow_V2_Roundtrip_Mismatch : BOOL;\n", ""),
    ("    L_Shadow_V2_First_Mismatch_Rule : INT;\n", ""),
    ("    L_V2_Switch_Enabled : BOOL;\n", ""),
    ("    L_V2_Path_Ready : BOOL;\n", ""),
    ("    L_V2_Using_Legacy_Fallback : BOOL;\n", ""),

    ("L_Compat_All_OK := TRUE;\n", ""),
    ("L_Compat_First_Warning := '';\n", ""),
    ("L_Compat_First_Warning_Latched := FALSE;\n", ""),
    ("L_Shadow_V2_Enabled := TRUE;\n", ""),
    ("L_Shadow_V2_Roundtrip_Mismatch := FALSE;\n", ""),
    ("L_Shadow_V2_First_Mismatch_Rule := 0;\n", ""),
    ("L_V2_Switch_Enabled := FALSE;\n", ""),
    ("L_V2_Path_Ready := FALSE;\n", ""),
    ("L_V2_Using_Legacy_Fallback := TRUE;\n", ""),

    (
"""    // Inlined from FB_Rule_Compatibility_Package:
    // current compatibility path is a trivial field copy from ST_User_Rule to ST_Rule.
    IF L_Shadow_V2_Enabled THEN
        // Since the inlined mapping is identity on compared fields,
        // roundtrip mismatch detection becomes a direct self-consistency check.
        // No mismatch is expected from the compatibility layer itself.
    END_IF;

    // Phase 4 scaffold: optional V2 switch point.
    // Current state: always remain on legacy behavior.
    // Future state: when V2 path is implemented and validated,
    // this block becomes the controlled branch point.
    IF L_V2_Switch_Enabled AND L_V2_Path_Ready THEN
        L_V2_Using_Legacy_Fallback := FALSE;
        // V2 action-generation path placeholder.
        // No runtime behavior change yet.
    ELSE
        L_V2_Using_Legacy_Fallback := TRUE;
    END_IF;
""",
"""    // Inlined from FB_Rule_Compatibility_Package:
    // current compatibility path is a trivial field copy from ST_User_Rule to ST_Rule.

""")
]

for old, new in replacements:
    text = text.replace(old, new)

path.write_text(text, encoding="utf-8")
print("OK: removed internal scaffold from FB_Rule_Engine.st")
