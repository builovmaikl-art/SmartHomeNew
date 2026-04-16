# Repository Write Rules — SmartHomeNew

## Purpose
Practical rules for making safe repository changes during architecture work and iterative development.

## Core principles
- Code changes must follow the engineering workflow from `docs/MASTER_GUIDE.md` and `docs/WORKFLOW.md`.
- Safety behavior must not be changed implicitly.
- Prefer incremental refactoring over large rewrites.
- New logic should be added first, then connected, then used to replace old logic, and only after that may obsolete code be removed.
- Documentation updates are part of the work, not an optional follow-up.

## Change order
1. Clarify the intended change.
2. Check current code and docs.
3. Record active work / findings in `docs/WORK_NOTES.md`.
4. Update architecture / work docs if a decision is made.
5. Apply code changes in small, reviewable steps.
6. Verify that fail-safe behavior and alarm/fault separation are preserved.
7. Remove temporary scaffolding only after replacement is wired and verified.

## Safe write strategy
Use this order of preference:
1. Update existing files directly using the repository toolchain when supported.
2. If direct update is unavailable, prepare an exact patch plan before any workaround.
3. If a workaround is required, prefer full-file replacement only when:
   - the exact current file content has been re-read,
   - the replacement is intentional and complete,
   - no partial edits are being guessed.
4. Do not leave duplicate temporary managers or parallel sources of truth in the repository.

## Temporary code rules
- Temporary MVP/helper files must be clearly marked as temporary.
- A temporary file must have an explicit retirement plan.
- If the production path is confirmed elsewhere, the temporary file must be removed.

## State / safety rules
- Safety latching belongs in dedicated safety logic.
- System mode / policy logic belongs in state orchestration logic.
- `GVL_STATE`, `GVL_ALARM`, and `GVL_COMMAND` must not gain overlapping ownership without an explicit architectural decision.
- New global commands must not be introduced casually.

## Documentation rules
- Decisions go to the proper docs, not only chat history.
- Open questions and deferred tasks go to `docs/WORK_NOTES.md`.
- When TZ, code, and docs differ, the difference must be recorded explicitly.

## Commit style
- One logical change per commit when possible.
- Commit messages should describe intent, not only mechanics.
- Avoid noisy helper artifacts in the project tree.

## Current note
At the current stage of repository work, direct creation of new files is available through the connected tooling, while editing existing files may require additional tool support or a controlled full-file replacement workflow.

## Mobile Mode

- One change = one file = one commit
- Avoid large batch edits from mobile
- Prefer append-only or full-file replacement strategy
- Always verify file after commit
