# WORKFLOW

## Phase Model
1. Architecture
2. Stabilization
3. Docs Alignment
4. Freeze
5. Next Stage

## Strict Execution Order
1. Discussion
2. Confirmation
3. Silent preparation of changes
4. Save changes into `steps/YYYY-MM-DD_*`
5. Build a single package on command
6. Provide terminal commands to update / apply / sync with `main`
7. Receive terminal log
8. Verify against actual repo files
9. Move forward only after successful verification

## Execution Rules
- Steps-based changes only
- No chat noise
- Batch apply → verify → then discuss
- Repo is source of truth
- Do not treat step packages as applied results
- Do not mark a task complete before repo verification

## Post-task Output
After each completed task provide:
- short summary of changes
- verification status
- next possible steps (2–3 options)
- recommended next step
