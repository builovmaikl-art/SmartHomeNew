#!/bin/bash
set -e

mkdir -p diagnostics/$(date +%Y_%m_%d)
mkdir -p компилятор/logs

LOG="diagnostics/$(date +%Y_%m_%d)/step_12_compile_smoke.log"

{
  echo "== START COMPILE SMOKE =="
  echo "-- ROOT --"
  pwd
  echo
  echo "-- PYTHON --"
  python3 --version
  echo
  echo "-- COMPILER DIR --"
  ls -la компилятор
  echo
  echo "-- RUN --"
} > "$LOG" 2>&1

python3 компилятор/import_codesys_FINAL.py >> "$LOG" 2>&1

{
  echo
  echo "-- OUTPUT CHECK --"
  find компилятор -maxdepth 2 | sort | head -n 200
  echo
  echo "== END =="
} >> "$LOG" 2>&1

git add -A
git commit -m "test: compile smoke after migration" || true

git fetch origin
git rebase origin/main || {
  git rebase --abort 2>/dev/null || true
  git pull --no-rebase origin main || true
}

git push origin main || true
