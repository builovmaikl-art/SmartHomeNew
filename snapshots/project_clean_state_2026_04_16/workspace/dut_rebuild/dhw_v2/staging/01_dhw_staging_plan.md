# DHW Staging Plan

## Goal
Introduce a shadow (staging) path for DHW V2 without affecting runtime.

## Runtime source confirmed
Active runtime file: `FB_DHW_Manager.st`

## Real legacy signals available
- VI_Temp
- VI_Pressure
- VI_Config.Target_Temp
- VO_Heating_Pump
- VO_Circ_Pump
- policy flags and emergency stop path

## Steps
1. Build V2 command/state from legacy signals
2. Run V2 core in parallel
3. Collect shadow outputs
4. Next step: integrate staging into runtime shadow-only
