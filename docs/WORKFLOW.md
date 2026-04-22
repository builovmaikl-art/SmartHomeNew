# WORKFLOW

## Phase Model
1. Architecture
2. Stabilization
3. Docs Alignment
4. Freeze
5. Next Stage

## Execution Modes

### Full Verification Mode
- steps-based changes
- terminal execution
- git diff + logs

### Analytical Verification Mode
- repository inspection only
- no execution

### Direct Repository Modification Mode
- assistant modifies repository directly
- verification via repository file state

---

## Strict Execution Order

### Full Mode
1. Discussion
2. Confirmation
3. Silent preparation of changes
4. Save changes into `steps/YYYY-MM-DD_*`
5. Build package
6. Terminal execution
7. Receive log
8. Verify against repo
9. Continue

### Direct Repository Mode
1. Discussion
2. Confirmation
3. Direct repository modification
4. Verify via repository state (GitHub)
5. Continue

---

## Execution Rules
- Repo is source of truth
- Do not mix verification modes implicitly
- Always state mode explicitly
- Do not claim execution without Full Mode

---

## Post-task Output
After each completed task provide:
- short summary of changes
- verification mode used
- verification status
- next possible steps (2–3 options)
- recommended next step
