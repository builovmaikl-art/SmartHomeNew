# Heating Protection — Phase 3 (Arbitrated real enforcement baseline)

## Status
OK: compiled, integrated

## Layers
1. Observer
2. Request layer
3. Priority arbitration
4. Real enforcement bridge
5. Telemetry
6. Cooldown / anti-thrashing

## Real Effects
- force manifold pumps for freeze protection
- close overheated floor-heating circuits

## Arbitration
- pump force blocked in SAFE_STOP and on emergency stop
- zone lock allowed as protective restriction

## Telemetry
- event counters
- last event time
- last event text

## Cooldown
- pump hold: 30s
- zone lock hold: 60s

## Next
- calibration verification line
- thresholds tuning
- optional export / HMI polish
