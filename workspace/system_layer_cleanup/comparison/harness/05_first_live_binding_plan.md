# First Live CoreKernel Comparison Binding

## Goal
Prepare the first real binding for legacy vs shadow comparison.

## Selected legacy source
- GVL_STATUS.G_Is_Active_PLC

## Binding model
Harness input:
- VI_Legacy_Path_Ready := GVL_STATUS.G_Is_Active_PLC

Harness other inputs:
- VI_System_Time_MS := GVL_SYSTEM.SYSTEM_TIME_MS (placeholder until exact runtime bind point is chosen)
- VI_IsActivePLC := GVL_STATUS.G_Is_Active_PLC

## Rules
- no runtime patching yet
- no GVL writes from harness
- observation only
