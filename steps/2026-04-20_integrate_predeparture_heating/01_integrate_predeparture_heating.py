#!/usr/bin/env python3
from pathlib import Path

# ---------------------------
# 1. FB_Rule_Engine — add output
# ---------------------------
rule_path = Path("FB_Rule_Engine.st")
rule = rule_path.read_text(encoding="utf-8")

if "VO_Preheat_Request" not in rule:
    rule = rule.replace(
        "VAR_OUTPUT",
        "VAR_OUTPUT\n    VO_Preheat_Request : BOOL; // pre-departure heating trigger"
    )

# simple safe insertion (end of logic)
if "PREHEAT_RULE_INSERT" not in rule:
    rule += """

// --- PREHEAT RULE INSERT ---
IF (GVL_STATUS.G_Departure_Time > 0) THEN
    IF (GVL_STATUS.G_Departure_Time - GVL_STATUS.G_System_Time_MS) < 10800000 THEN
        IF GVL_STATE.G_System_Mode <> MODE_SAFE_STOP THEN
            VO_Preheat_Request := TRUE;
        END_IF;
    END_IF;
END_IF;
"""
rule_path.write_text(rule, encoding="utf-8")

# ---------------------------
# 2. FB_Scenario_Manager — handle preheat
# ---------------------------
sc_path = Path("FB_Scenario_Manager.st")
sc = sc_path.read_text(encoding="utf-8")

if "VI_Preheat_Request" not in sc:
    sc = sc.replace(
        "VAR_INPUT",
        "VAR_INPUT\n    VI_Preheat_Request : BOOL;"
    )

if "PREHEAT_SCENARIO_INSERT" not in sc:
    sc += """

// --- PREHEAT SCENARIO INSERT ---
IF VI_Preheat_Request THEN
    GVL_HEATING.G_Preheat_Active := TRUE;
END_IF;
"""
sc_path.write_text(sc, encoding="utf-8")

# ---------------------------
# 3. PRG_System wiring
# ---------------------------
prg_path = Path("PRG_System.st")
prg = prg_path.read_text(encoding="utf-8")

# connect rule -> scenario
old_call = "fbScenarioManager("
if "VI_Preheat_Request :=" not in prg:
    prg = prg.replace(
        "fbScenarioManager(",
        "fbScenarioManager(\n        VI_Preheat_Request := fbRuleEngine.VO_Preheat_Request,"
    )

prg_path.write_text(prg, encoding="utf-8")

print("OK: integrated pre-departure heating as rule + scenario")
