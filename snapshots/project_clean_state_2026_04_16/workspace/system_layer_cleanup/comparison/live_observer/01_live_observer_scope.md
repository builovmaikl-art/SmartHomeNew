# CoreKernel Live Observer Scope

## Goal
Prepare a non-intrusive live observer for PRG_System that can later host the CoreKernel comparison harness.

## Safety rules
- no automatic patching of PRG_System in this step
- no writes to GVL from the observer
- observer call must be placed at the end of the PRG_System cycle in a future step
