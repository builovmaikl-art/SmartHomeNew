from pathlib import Path

targets = {
    "FB_Alarm_Manager.st": [
        ("    // Inlined from FB_Alarm_Compatibility_Package:\n", ""),
        ("    // current compatibility path is a no-op roundtrip with VO_OK always TRUE.\n", ""),
    ],
    "FB_Rule_Engine.st": [
        ("    // Inlined from FB_Rule_Compatibility_Package:\n", ""),
        ("    // current compatibility path is a trivial field copy from ST_User_Rule to ST_Rule.\n", ""),
    ],
    "FB_Socket_Manager.st": [
        ("    // Socket V2 shadow (phase2)\n", ""),
    ],
    "FB_DHW_Manager.st": [
        ("    // DHW V2 staging layer\n", ""),
    ],
    "FB_Ventilation_System_Manager.st": [
        ("// Ventilation policy layer (phase3/v2)\n", "// Ventilation policy layer\n"),
    ],
    "FB_Lighting_Blinds_Manager.st": [
        ("    // Blinds V2 shadow (phase2)\n", ""),
        ("    // Lighting V2 shadow (phase2)\n", ""),
    ],
    "FB_Heating_System_Manager.st": [
        ("    // Heating V2 staging layer\n", ""),
        ("// Heating policy layer (phase2)\n", "// Heating policy layer\n"),
    ],
}

for filename, replacements in targets.items():
    path = Path(filename)
    text = path.read_text(encoding="utf-8")
    original = text
    for old, new in replacements:
        text = text.replace(old, new)
    if text != original:
        path.write_text(text, encoding="utf-8")
        print(f"UPDATED: {filename}")
    else:
        print(f"NOCHANGE: {filename}")
