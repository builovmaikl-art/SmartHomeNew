# Watchdog + SystemHealth Shadow Scope

## Goal
Prepare the next CoreKernel shadow slices for watchdog and system health.

## Source
PRG_System core kernel mapping:
- fbWatchdog call region
- fbSystemHealth call region
- dependency chain between watchdog -> system health -> state manager

## Rules
- no runtime integration
- no GVL writes in this step
- structure only
