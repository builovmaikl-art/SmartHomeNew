#!/usr/bin/env bash
set -euo pipefail

python3 <<'PY'
from pathlib import Path
p = Path('PRG_System.st')
t = p.read_text(encoding='utf-8')
old = (
    "IF GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_NORMAL THEN\n"
    "    L_Scenario_Req_Operator := GVL_COMMAND.G_Scenario_Request_Operator;\n"
    "ELSE\n"
    "    L_Scenario_Req_Operator := E_SCENARIO_TYPE.SCENARIO_NONE;\n"
    "END_IF;"
)
new = "L_Scenario_Req_Operator := GVL_COMMAND.G_Scenario_Request_Operator;"
count = t.count(old)
if count != 1:
    raise SystemExit(f'anchor count={count}, expected 1')
t = t.replace(old, new, 1)
p.write_text(t, encoding='utf-8')
print('OK: operator gate removed')
PY

git add PRG_System.st
git commit -m "fix: always publish operator scenario request to policy"
git push
