#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
LOG_DIR="$ROOT/компилятор/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/step2_2_patch.log"

exec > >(tee "$LOG_FILE") 2>&1

echo "=== step2_2_patch start ==="
date
pwd

if [[ ! -f "$ROOT/PRG_System.st" ]]; then
  echo "ERROR: run from repository root"
  exit 1
fi

GOOD_BLOB_SHA="2dcab7aef742ae13c9f87905d8bad74e05fc6a63"

echo "--- restore PRG_System from known-good blob ---"
if git cat-file -e "${GOOD_BLOB_SHA}^{blob}" 2>/dev/null; then
  git cat-file -p "$GOOD_BLOB_SHA" > "$ROOT/PRG_System.st"
else
  echo "ERROR: blob $GOOD_BLOB_SHA not found in local git objects"
  echo "Try: git fetch --all --tags --force"
  exit 1
fi

echo "--- apply controlled PRG_System patch ---"
python3 <<'PY'
from pathlib import Path
import re

p = Path('PRG_System.st')
t = p.read_text(encoding='utf-8')

old_gate = (
    "IF GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_NORMAL THEN\n"
    "    L_Scenario_Req_Operator := GVL_COMMAND.G_Scenario_Request_Operator;\n"
    "ELSE\n"
    "    L_Scenario_Req_Operator := E_SCENARIO_TYPE.SCENARIO_NONE;\n"
    "END_IF;\n"
    "L_Scenario_Req_Gateway := E_SCENARIO_TYPE.SCENARIO_NONE;\n"
    "L_Scenario_Req_Rule := E_SCENARIO_TYPE.SCENARIO_NONE;\n"
    "GVL_POLICY.G_Scenario_Request_Gateway := E_SCENARIO_TYPE.SCENARIO_NONE;\n"
    "GVL_POLICY.G_Scenario_Request_Rule := E_SCENARIO_TYPE.SCENARIO_NONE;"
)
new_gate = (
    "IF GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_NORMAL THEN\n"
    "    L_Scenario_Req_Operator := GVL_COMMAND.G_Scenario_Request_Operator;\n"
    "ELSE\n"
    "    L_Scenario_Req_Operator := E_SCENARIO_TYPE.SCENARIO_NONE;\n"
    "END_IF;\n"
    "GVL_POLICY.G_Scenario_Request_Operator := L_Scenario_Req_Operator;\n"
    "L_Scenario_Req_Gateway := E_SCENARIO_TYPE.SCENARIO_NONE;\n"
    "L_Scenario_Req_Rule := E_SCENARIO_TYPE.SCENARIO_NONE;\n"
    "GVL_POLICY.G_Scenario_Request_Gateway := E_SCENARIO_TYPE.SCENARIO_NONE;\n"
    "GVL_POLICY.G_Scenario_Request_Rule := E_SCENARIO_TYPE.SCENARIO_NONE;"
)
if old_gate not in t:
    raise SystemExit('operator publish anchor not found')
t = t.replace(old_gate, new_gate, 1)

pattern = re.compile(
    r"// === SCENARIO PRIORITY RESOLUTION ===.*?END_IF;\n\nfbScenarioGuard\(",
    re.S,
)
replacement = (
    "// === SCENARIO POLICY CONSUMPTION ===\n"
    "L_Scenario_Req_Final := GVL_POLICY.G_Scenario_Intent;\n"
    "L_Scenario_Intent := GVL_POLICY.G_Scenario_Intent;\n"
    "L_Scenario_Source := GVL_POLICY.G_Scenario_Source;\n\n"
    "fbScenarioGuard("
)
new_t, n = pattern.subn(replacement, t, count=1)
if n != 1:
    raise SystemExit(f'scenario owner block replace failed: {n}')
t = new_t

p.write_text(t, encoding='utf-8')
print('OK: PRG_System restored and patched')
PY

echo "--- git status ---"
git status --short PRG_System.st "$LOG_FILE" || true

echo "--- commit ---"
git add PRG_System.st "$LOG_FILE"
git commit -m "step2.2: restore PRG_System and switch scenario ownership to PRG_Policy" || true

echo "--- push ---"
git push

echo "=== step2_2_patch done ==="
