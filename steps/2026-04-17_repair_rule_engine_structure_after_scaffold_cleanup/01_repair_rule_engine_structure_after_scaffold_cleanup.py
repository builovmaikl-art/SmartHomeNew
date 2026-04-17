from pathlib import Path

path = Path("FB_Rule_Engine.st")
text = path.read_text(encoding="utf-8")

broken = """FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_RULES DO
    // Inlined from FB_Rule_Compatibility_Package:
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
            END_IF;

    VO_Actions[L_i].Active := FALSE;
"""

fixed = """FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_RULES DO
    // Inlined from FB_Rule_Compatibility_Package:
    // current compatibility path is a trivial field copy from ST_User_Rule to ST_Rule.

    VO_Actions[L_i].Active := FALSE;
"""

if broken not in text:
    raise SystemExit("Broken scaffold block not found in FB_Rule_Engine.st")

text = text.replace(broken, fixed, 1)
path.write_text(text, encoding="utf-8")
print("OK: repaired FB_Rule_Engine.st after scaffold cleanup")
