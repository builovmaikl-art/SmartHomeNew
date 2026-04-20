#!/usr/bin/env python3
from pathlib import Path

# ---------------------------
# 1. Create ST_Heating_Command
# ---------------------------
dut_path = Path("ST_Heating_Command.st")
if not dut_path.exists():
    dut_path.write_text("""TYPE ST_Heating_Command :
STRUCT
    Enable              : BOOL;
    Target_Temperature  : REAL;
    Priority            : INT; // higher = stronger
END_STRUCT
END_TYPE
""", encoding="utf-8")

# ---------------------------
# 2. Extend Heating Manager
# ---------------------------
hm_path = Path("FB_Heating_System_Manager.st")
hm = hm_path.read_text(encoding="utf-8")

if "VI_Command" not in hm:
    hm = hm.replace(
        "VAR_INPUT",
        "VAR_INPUT\n    VI_Command : ST_Heating_Command;"
    )

# inject command logic
if "HEATING_COMMAND_INSERT" not in hm:
    hm += """

// --- HEATING COMMAND INSERT ---
IF VI_Command.Enable THEN
    // apply temperature with priority concept (simplified for now)
    GVL_HEATING.G_Target_Temperature := VI_Command.Target_Temperature;
END_IF;
"""

hm_path.write_text(hm, encoding="utf-8")

# ---------------------------
# 3. Rule Engine — build command
# ---------------------------
rule_path = Path("FB_Rule_Engine.st")
rule = rule_path.read_text(encoding="utf-8")

if "VO_Heating_Command" not in rule:
    rule = rule.replace(
        "VAR_OUTPUT",
        "VAR_OUTPUT\n    VO_Heating_Command : ST_Heating_Command;"
    )

if "PREHEAT_COMMAND_INSERT" not in rule:
    rule += """

// --- PREHEAT COMMAND INSERT ---
IF VO_Preheat_Request THEN
    VO_Heating_Command.Enable := TRUE;
    VO_Heating_Command.Target_Temperature := 22.0;
    VO_Heating_Command.Priority := 10;
END_IF;
"""

rule_path.write_text(rule, encoding="utf-8")

# ---------------------------
# 4. PRG_System wiring
# ---------------------------
prg_path = Path("PRG_System.st")
prg = prg_path.read_text(encoding="utf-8")

if "VI_Command :=" not in prg:
    prg = prg.replace(
        "fbHeatingSystemManager(",
        "fbHeatingSystemManager(\n        VI_Command := fbRuleEngine.VO_Heating_Command,"
    )

prg_path.write_text(prg, encoding="utf-8")

print("OK: heating orchestration cleanup applied")
