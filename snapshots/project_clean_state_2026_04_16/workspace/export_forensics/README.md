# Export Forensics Workspace

Purpose: temporary workspace for safe dissection of the original CODESYS `*.export` file before any reintegration work.

## Current status
- workspace created
- analysis notes scaffold created
- original `*.export` file not copied automatically in this step

## Why original file was not auto-copied
The repository-facing tools available in this session could not reliably discover the exact export filename/path from the current repo view. To avoid copying the wrong file or fabricating a path, this workspace was prepared without touching the export source.

## Recommended next step
When returning to this task:
1. place or confirm the exact export filename/path in repo root
2. copy the original export into this workspace as a frozen baseline
3. run structural analysis against the frozen copy only

## Intended files in this workspace
- `ORIGINAL_EXPORT_BASELINE.*` — untouched baseline copy
- `EXPORT_STRUCTURE_NOTES.md` — findings and recurring patterns
- `EXPORT_REINTEGRATION_CHECKLIST.md` — rules for safe backport into export
