# EXECUTION CONVENTIONS

## New block placement
- New project blocks are created directly in the repository root next to the main project files.
- New project blocks are not created inside `steps/`.

## Repair steps
- Changes to existing code are prepared in a dedicated folder under `steps/`.
- That folder accumulates deterministic repair scripts.
- The scripts are not treated as applied implementation until accepted and applied as a package.

## Acceptance workflow
1. Prepare step package.
2. Review package.
3. Accept package explicitly.
4. Apply package.
5. Verify by logs and repository state.
