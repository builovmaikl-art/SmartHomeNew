# Core Kernel Shadow Execution Notes

## Goal
Prepare a second-stage shadow wrapper for future PRG_System core kernel extraction.

## Current stage
- FB_CoreKernel_DRAFT exists
- FB_CoreKernel_Shadow_Stub_DRAFT exists
- FB_CoreKernel_Shadow_Exec_DRAFT wraps the shadow stub

## Rules
- no runtime integration yet
- no GVL writes
- no mode publish side effects

## Next step
Map exact input/output boundary for first safe shadow comparison.
