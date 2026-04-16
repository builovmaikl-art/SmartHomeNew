from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

var_anchor = "    fbScenarioManager : FB_Scenario_Manager;\n"
var_insert = "    fbScenarioGuard : FB_Scenario_Transition_Guard;\n"

if var_insert not in text:
    if var_anchor not in text:
        raise SystemExit("fbScenarioManager anchor not found")
    text = text.replace(var_anchor, var_anchor + var_insert, 1)

call_anchor = "fbScenarioManager(\n"
guard_block = """fbScenarioGuard(
    VI_Current_Scenario := GVL_STATUS.G_Current_Scenario,
    VI_Target_Scenario := L_Scenario_Intent
);

IF NOT fbScenarioGuard.VO_Transition_Allowed THEN
    GVL_STATUS.G_Diagnostics.HMI_Last_Message := CONCAT('Scenario guard: ', fbScenarioGuard.VO_Reason);
END_IF;

"""

if guard_block not in text:
    if call_anchor not in text:
        raise SystemExit("fbScenarioManager call anchor not found")
    text = text.replace(call_anchor, guard_block + call_anchor, 1)

path.write_text(text, encoding="utf-8")
print("OK: attached scenario guard in diagnostic-only mode")
