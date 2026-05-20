# AGENTS.md — SmartHomeNew repository instructions

## 1. Source of truth

Work only from the current repository state.

Priority order when information conflicts:

```text
actual repository code
> current AGENTS.md
> formal project specification / technical requirements
> current project documentation
> chat history
> assumptions
```

Never treat old reports, previous chat conclusions, or remembered repository state as truth.
Always inspect the current files before analysis or modification.

---

## 2. Mandatory first step

Before analysis, planning, coding, cleanup, or refactoring:

1. Read `AGENTS.md`.
2. Inspect the current files directly involved in the task.
3. Read `ТЗ обновлен.txt` when the task depends on physical object topology, zones, equipment, safety requirements, or domain boundaries.
4. Inspect current project documentation only when it is directly relevant to the requested task.

Do not load obsolete audit artifacts as guidance.
Do not infer current architecture from deleted, archived, or historical reports.

---

## 3. Operating mode

The normal operating mode is Direct Repository Modification Mode through the connected GitHub agent/API.

Rules:

```text
- fetch before changing a file
- use full-file replacement for existing code files
- update only the intended file or files
- fetch the changed file back immediately after update
- verify repository file state after every modification
- clearly distinguish repository file-state verification from build/runtime verification
```

Do not claim terminal, compiler, PLC, runtime, or build verification unless it was actually executed and the output was inspected.

If terminal/full-repository execution is unavailable, use Analytical Verification Mode:

```text
- inspect repository files
- check symbol consistency
- check control and data flow
- check referenced enum values and GVL fields
- check array bounds and declared names
- report limits honestly
```

---

## 4. GitHub agent tools and fallbacks

The connected GitHub agent can normally provide these tool groups. Always use the actual tool names exposed in the current session.

### 4.1 Available tool groups

```text
Access / permissions:
- get_user_login
- get_profile
- get_repo
- get_repo_collaborator_permission
- check_repo_initialized

Repository read / inspection:
- fetch_file
- fetch
- fetch_blob
- fetch_commit
- compare_commits
- search
- search_commits
- search_branches

Normal file mutation:
- create_file
- update_file
- delete_file

Low-level git mutation:
- create_blob
- create_tree
- create_commit
- update_ref
- create_branch

Pull request / issue workflow:
- create_pull_request
- fetch_pr
- fetch_pr_patch
- get_pr_diff
- get_pr_info
- add_review_to_pr
- create_issue
- update_issue
- add_comment_to_issue

GitHub Actions inspection:
- fetch_commit_workflow_runs
- fetch_workflow_run_jobs
- fetch_workflow_job_logs
- fetch_workflow_job_steps
- fetch_workflow_run_artifacts
- get_commit_combined_status
```

Use contents API operations (`create_file`, `update_file`, `delete_file`) for ordinary file changes. Use low-level git operations only when contents API operations are insufficient or blocked.

### 4.2 Known connector difficulties

Known issues:

```text
- fetch_file works on files, not directories
- repository search may miss files or return incomplete discovery results
- delete_file may fail or be blocked even when repository permissions are valid
- main may move while work is in progress because GitHub Actions or another actor pushed new commits
- large diffs or large files may be truncated in tool output
- local clone / terminal / compiler access may be unavailable
```

Safe fallbacks:

```text
- for directory discovery, combine search with direct fetch_file checks for known paths
- for directory removal, use a low-level tree commit and verify the path returns 404 afterward
- for file removal when delete_file fails, use a low-level tree commit that removes only the intended path
- before update_ref, inspect the prepared commit with fetch_commit
- update main only as fast-forward unless the user explicitly requests otherwise
- if update_ref reports a non-fast-forward update, fetch current main again and recreate the commit on top of the new head
- after automation pushes, re-check current main before continuing
- for large diffs, verify by changed file list and targeted fetch_file calls
- if build execution is unavailable, report only repository file-state or analytical verification
```

Low-level safe mutation sequence:

```text
1. fetch current main
2. prepare a tree from current main
3. create a commit with current main as parent
4. inspect the new commit diff
5. update main with a fast-forward ref update
6. verify changed files by fetch_file or expected 404
```

---

## 5. File integrity rule

After every repository modification:

```text
1. Re-read the modified file from the repository.
2. Verify that the full structure is present.
3. Verify no truncated logic blocks.
4. Verify no missing CASE branches, declarations, methods, or function blocks.
5. Verify no unrelated logic was overwritten.
6. Only then continue to the next change.
```

Forbidden:

```text
- hidden partial edits
- blind patching into existing logic
- multiple runtime-file modifications without intermediate verification
- continuing after failed or partial update without checking repository state
```

For existing runtime files, prefer:

```text
fetch full file → prepare complete replacement → update file → fetch again → verify
```

---

## 6. Runtime authority boundaries

Preserve deterministic runtime authority separation.

General pipeline principle:

```text
IO acquisition
→ input normalization
→ scenario / safety intent
→ command arbitration
→ domain execution
→ output projection
→ physical IO
```

Observability, explainability, trace, diagnostics, debug views, dashboards, and compatibility publication surfaces must not become hidden control layers.

---

## 7. Ownership rules

### Input

```text
PRG_IO_Read owns raw acquisition and calibration.
PRG_Input_Processing owns normalized input publication.
High-level logic should prefer normalized input models over raw legacy state unless the reason is explicit.
```

### Scenario

Scenario logic owns behavior intent and scoring only.
It must not write physical IO, command shadow, or domain output GVLs.

### Safety

Safety logic has priority over comfort, behavior, user requests, adaptation, and domain control.
Safety intent must flow through the safe command path and must not be bypassed by HMI or user intent.

### Command

Command arbitration owns command shadowing and conflict elimination.
It must reset command state deterministically each cycle and eliminate contradictory command pairs before domain execution.

### Domain

Domain PRGs own domain execution only.
Domain PRGs must not write physical IO directly.

### IO write

The final IO write layer is the only final physical output projection layer.
Final clamps here are last-line output protection, not a second independent command system.

### Observability

Trace, explainability, diagnostics, and debug views are read-only observability layers.
They must not control runtime outputs.

---

## 8. HMI / dashboard rule

HMI and dashboard surfaces are read-only by default.

Allowed control path:

```text
HMI / dashboard
→ user intent
→ safety / command pipeline
→ domain execution
→ output projection
→ IO
```

Forbidden paths:

```text
HMI → physical IO
HMI → command shadow
HMI → domain output GVLs
HMI → adaptive weights directly
HMI → hidden safety bypass
```

---

## 9. Editing discipline

Use deterministic anchors when they already exist:

```text
// === BEGIN BLOCK_NAME ===
...
// === END BLOCK_NAME ===
```

Do not rely on ambiguous anchors such as a lone `END_IF`, `END_CASE`, or repeated comment line.

When creating scripts or generated artifacts, keep them deterministic and place them only where appropriate for the repository structure.

Do not add runtime layers unless they are connected into the actual execution flow and verified against current repository files.

---

## 10. Cleanup discipline

Cleanup is allowed only when it follows the user's current instruction and current repository state.

Before deleting or simplifying active runtime code, verify that the target is not required by:

```text
- runtime execution
- safety behavior
- command arbitration
- IO projection
- domain output
- configuration
- HMI/user intent path
- trace/explainability/debug visibility
```

Audit/report artifacts under `docs/audit/` are not authoritative project instructions.
They may be removed when requested and must not override current code or `AGENTS.md`.

---

## 11. Mandatory runtime checks after code changes

For runtime-affecting changes, check at minimum:

```text
- referenced enum values exist
- referenced GVL fields exist
- arrays use declared bounds
- command shadow reset covers all relevant fields
- domain output GVLs are consumed by the final IO write layer
- scenario, explainability, diagnostics, and debug layers do not control outputs
- safety cannot be bypassed by user intent, HMI, dashboard, or adaptive profile changes
```

If these checks are analytical only, state that clearly.

---

## 12. Forbidden patterns

```text
- using chat memory as repository truth
- using old audit reports as current architecture truth
- claiming build/runtime success without evidence
- direct HMI writes to IO, command shadow, or domain outputs
- scenario writing command shadow or IO
- domain writing physical IO directly
- debug/explainability/diagnostics writing control signals
- safety bypass through user intent or dashboard controls
- partial hidden file modifications
- accidental truncation of files
- adding disconnected runtime layers
- creating duplicate blackbox/debug systems instead of using existing trace/debug state
```
