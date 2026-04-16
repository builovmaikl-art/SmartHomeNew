# Safety Shadow Scope

## Goal
Prepare the second CoreKernel logic slice as a shadow-only extraction.

## Source
PRG_System core kernel mapping:
- fbSafety call region
- safety-related upstream/downstream coupling

## Rules
- no runtime integration
- no GVL writes in this step
- structure only
