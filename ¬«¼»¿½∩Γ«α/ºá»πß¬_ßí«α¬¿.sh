#!/bin/bash

python3 компилятор/import_codesys_FINAL.py > компилятор/logs/final_test.log 2>&1
git add -A
git commit -m "test: run full chain build"
git push
