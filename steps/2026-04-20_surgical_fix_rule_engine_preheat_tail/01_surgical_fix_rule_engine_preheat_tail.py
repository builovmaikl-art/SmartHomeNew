from pathlib import Path

rule_path = Path("FB_Rule_Engine.st")
text = rule_path.read_text(encoding="utf-8")

broken_tail = """

// --- PREHEAT COMMAND INSERT ---
IF VO_Preheat_Request THEN
    VO_Heating_Command.Enable := TRUE;
    VO_Heating_Command.Target_Temperature := 22.0;
    VO_Heating_Command.Priority := 10;
END_IF;
"""

if broken_tail in text:
    text = text.replace(broken_tail, "\n", 1)
    rule_path.write_text(text, encoding="utf-8")
    print("OK: removed broken PREHEAT COMMAND INSERT tail from FB_Rule_Engine.st")
else:
    print("OK: broken PREHEAT COMMAND INSERT tail not present")

# optional: keep the simple trigger output explicitly reset for determinism
text = rule_path.read_text(encoding="utf-8")
anchor = "IF NOT VI_IsActivePLC THEN RETURN; END_IF;\n"
inject = """IF NOT VI_IsActivePLC THEN RETURN; END_IF;

VO_Preheat_Request := FALSE;
"""
if inject not in text:
    if anchor not in text:
        raise SystemExit("Anchor not found for VO_Preheat_Request reset")
    text = text.replace(anchor, inject, 1)
    rule_path.write_text(text, encoding="utf-8")
    print("OK: added deterministic reset for VO_Preheat_Request")
