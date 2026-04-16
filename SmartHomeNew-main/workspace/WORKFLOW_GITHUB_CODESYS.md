# 🧠 WORKFLOW: GitHub + CODESYS Integration

---

# 1. PURPOSE

This document defines the working rules, tools, and constraints for interacting with the SmartHomeNew repository and integrating with CODESYS.

---

# 2. CORE PRINCIPLES

- Never break runtime
- Always use small steps
- Prefer patching over rewriting
- Always commit after each step

---

# 3. WORKFLOW MODEL

ChatGPT → script → repo → user executes → commit → verify

---

# 4. TOOLS

## Git

Used for version control

## Python scripts

Used for patching and automation

Rules:
- stored in steps/
- one action per script
- safe to re-run

## Workspace

Temporary files and analysis

---

# 5. STRUCTURE

- steps/ → execution scripts
- docs/ → documentation
- workspace/ → temporary

---

# 6. STEP RULES

Each step:
- one task
- idempotent
- clearly named

---

# 7. EXECUTION

```
git pull
python script.py
git add .
git commit
git push
```

---

# 8. LIMITATIONS

## ChatGPT
- limited repo visibility
- cannot parse large export

## Mobile
- long commands break

Solution:
- use scripts

---

# 9. CODESYS STRATEGY

Use XML export

Allowed:
- modify ST body

Forbidden:
- modify structure

---

# 10. SUMMARY

Stable, step-based workflow

---

END
