# Deferred Tasks (Post-Architecture Phase)

## HMI Integration
- Display system mode
- Display root cause (type + source)
- Display latched status
- Provide reset button

## Logging / Event System
- Record fault events with timestamp
- Store first fault occurrences
- Maintain history

## Optimization
- Remove GVL_STATE as transport layer
- Replace with direct structured interfaces
- Reduce duplicated signals

## Advanced Diagnostics
- Fault counters
- MTBF estimation
- Priority tuning

## Notes
All tasks intentionally deferred after core architecture stabilization.
