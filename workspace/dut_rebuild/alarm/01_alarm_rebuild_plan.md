# Alarm DUT rebuild plan

## Problems in current model
- alarm storage and UI representation mixed
- lifecycle and display concerns combined
- weak extension path

## Target split
- ST_Alarm_Core_Record_V2
- ST_Alarm_View_Record_V2
- ST_Alarm_Event_V2

## Principle
Core alarm record must be storage/policy safe and UI-neutral.
