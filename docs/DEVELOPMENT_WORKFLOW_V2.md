# DEVELOPMENT WORKFLOW (Phase-Based V2)

## Core Principle
Development is performed in phases with accumulation of steps and a single final application.

---

## Workflow Model
1. Analysis / Discussion
2. Step Creation (NO apply)
3. Step Accumulation
4. Validation
5. FINAL_MEGA_STEP execution
6. Commit & Push

---

## Phase Structure
steps/YYYY-MM-DD_phaseX/

Contains:
- step_XX files
- audit / plan
- FINAL_*_PACKAGE.sh

---

## Rules

### No Partial Apply
Applying steps one-by-one is запрещено.

### Single Entry Point
Only FINAL_* script is executed.

### Repo = Truth
After phase → ignore steps, trust repo.

### Docs Required
Architecture must be documented.

### Recovery
If broken → create recovery package.

---

## Anti-Patterns
- Step-by-step apply
- Editing same block repeatedly
- Relying on memory

---

## Status
Version: v2
