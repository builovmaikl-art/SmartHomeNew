# EXECUTION CONVENTIONS UPDATE — 2026-04-05

This document refines the repository execution rules for architecture refactor work.
It supplements `docs/EXECUTION_CONVENTIONS.md`.

## 1. When NOT to use `steps/`

Do NOT use `steps/` as the primary application mechanism for:
- large PLC source files with unstable formatting
- files where CRLF/LF or exact text matching makes patch scripts fragile
- risky `replace(...)` edits that are harder to verify than a full-file rewrite

For these cases, use direct full-file replacement in the working tree, then verify by `git diff`.

## 2. Preferred method for complex FB refactor

For large existing files such as `FB_*.st` that need structural cleanup:
1. prepare the target file content
2. replace the full file locally in one controlled action
3. inspect `git diff`
4. commit only the resulting project files
5. push
6. verify in `main`

## 3. Role of `steps/`

`steps/` remains allowed only for:
- creating new files deterministically
- simple mechanical edits with stable structure
- batch helper tools that are proven reliable for the target files

`steps/` must not be pushed as a substitute for actual code changes.

## 4. Commit hygiene rule

When applying architecture work:
- commit the actual modified project files
- do not treat step/helper scripts as the result
- if helper scripts were used only locally, they should not be the only content of the commit

## 5. Verification rule

The accepted proof of progress is:
- changed project files in `git diff`
- successful push to `main`
- verification against actual repository file contents

Not accepted as proof of progress:
- existence of a helper script alone
- a step file committed without corresponding project file changes

## 6. Current operating convention

For the ongoing architecture migration:
- use direct full-file replacement for fragile manager/controller refactors
- use `steps/` only where it reduces risk instead of increasing it
- prioritize deterministic repository results over preserving a step-first ritual
