# PRG_System Decomposition Map

Date: 2026-04-30
Scope: Phase 5 PRG_System decomposition

## Rule

PRG_System remains untouched during extraction preparation. New PRG blocks are created as prepared ownership contours and must not be connected in MAIN until the final coordinated switch.

## Current ownership contours

| Contour | Current owner | Extracted target | Switch status | Risk |
|---|---|---|---|---|
| Init / recovery / persist manager / redundancy | PRG_System | PRG_System_Runtime_Base | Prepared | Medium |
| Health / state mode / diagnostics / HMI health | PRG_System | PRG_System_Health + GVL_SYSTEM_HEALTH | Prepared, not connected | High |
| Intent publication | PRG_System_Intent | PRG_System_Intent | Connected | Low |
| Evacuation + astro timer | PRG_System | PRG_System_Evacuation_Astro | Prepared | Low |
| Scenario arbitration + rules | PRG_System | PRG_System_Scenario_Rules | Prepared | Medium |
| Alarm orchestration + gateway intent | PRG_System | PRG_System_Alarm_Gateway | Prepared | Medium |
| BlackBox recorder | PRG_System | PRG_System_BlackBox | Prepared | Low |
| History manager | PRG_System | PRG_System_History | Prepared | Medium |
| Access / dangerous action / maintenance | PRG_System | PRG_System_Access_Maintenance | Prepared | Medium |
| Persistent snapshot mirror | PRG_System | PRG_System_Persistent_Snapshot | Prepared | Low |
| Event logging tails | PRG_System | PRG_System_Event_Logging | Prepared | Low |

## Prepared files created in this pass

- PRG_System_Runtime_Base.st
- PRG_System_Evacuation_Astro.st
- PRG_System_Scenario_Rules.st
- PRG_System_Alarm_Gateway.st
- PRG_System_BlackBox.st
- PRG_System_History.st
- PRG_System_Access_Maintenance.st
- PRG_System_Persistent_Snapshot.st
- PRG_System_Event_Logging.st

## Existing prepared files

- PRG_System_Intent.st
- PRG_System_Health.st
- GVL_SYSTEM_HEALTH.gvl

## Switch rule

Do not connect any prepared block while PRG_System still executes the same contour. Final switch must be a coordinated update of:

1. MAIN.st
2. PRG_System.st
3. Any required GVL bridge files

## Open debts

- Health is prepared but not switched.
- Time still has legacy calls inside PRG_System.
- PRG_System_Intent is connected, but the legacy declaration remains in PRG_System.
- Final PRG_System cleanup must be one complete-file replacement only.
