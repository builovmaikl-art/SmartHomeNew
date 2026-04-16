# IMPORT PIPELINE RULES (SINGLE SOURCE OF TRUTH)

## Current Status
Working:
- XML import into CODESYS
- FB implementation sync
- Missing FB clone via template

Not fully solved:
- VAR/interface integrity
- GVL import
- DUT verification in project
- Full compilation

## Core Rule
Always work from clean XML base.
Never fix broken XML — recreate new version.

## FB Pipeline (confirmed)
1. Copy base XML
2. Sync existing implementations
3. Clone missing FB from valid template
4. Replace only name and body
5. Import into CODESYS
6. Verify via anchors

## Anchors
FB only:
// >>> BULK_SYNC_ANCHOR

DUT/GVL:
no anchors

## L_* Errors
Indicates broken interface:
- VAR not mapped to localVars
- declaration corrupted

## Before Next Stage
- Clean duplicate FB using anchors
- Verify VAR sections
- Fix structurally broken blocks

## Truth
XML container works.
FB sync and insertion works.
Structure still partially unstable.
