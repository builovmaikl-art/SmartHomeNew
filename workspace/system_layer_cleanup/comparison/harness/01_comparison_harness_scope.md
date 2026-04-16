# CoreKernel Comparison Harness Scope

## Goal
Prepare a harness that will later compare legacy PRG_System path-ready behavior with CoreKernel shadow outputs.

## Inputs
- System time
- PLC active flag
- legacy path ready signal

## Outputs
- shadow path ready
- diff found

## Rules
- no runtime patching yet
- no GVL writes from the new harness
- structure only
