#!/bin/bash
set -e

SCRIPT_NAME=$1
COMMIT_MSG=$2
shift 2

python3 "$SCRIPT_NAME"

git add "$@"
git commit -m "$COMMIT_MSG"
git push
