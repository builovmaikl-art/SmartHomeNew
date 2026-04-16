# Alarm Pending Queue Extraction Plan

## Goal
Move the pending-alarm queue handling logic out of `FB_Alarm_Manager` and into `FB_Alarm_V2_Core_DRAFT` in a staged way.

## Scope of this package
- slot selection skeleton refinement
- ID assignment skeleton
- event pulse skeleton
- no runtime switch yet

## Non-goals
- do not migrate acknowledgement policy yet
- do not migrate active alarm lifecycle update yet
- do not migrate HMI projection yet
