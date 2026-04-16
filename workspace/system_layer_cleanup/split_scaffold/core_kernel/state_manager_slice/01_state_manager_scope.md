# StateManager Shadow Scope

## Goal
Prepare final CoreKernel slice: StateManager + System_Mode generation.

## Source
PRG_System core kernel mapping:
- fbStateManager call
- System_Mode calculation and publish

## Rules
- no runtime integration
- no GVL writes in this step
- structure only
