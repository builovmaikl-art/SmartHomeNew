# Phase 6 Modbus Map

Date: 2026-04-30
Scope: FB_Gateway_Interface after 16 heating circuit stabilization

## Source

The object specification requires 16 heating circuits. Gateway Modbus publishing now follows GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS instead of legacy fixed 8.

## Current Register Map

| Register range | Data | Notes |
|---|---|---|
| 0 | PLC / alarm status bitmask | Active PLC, security armed, flood, gas, fire |
| 1-16 | Floor heating temperatures x10 | 16 heating circuits |
| 17-32 | Room temperatures x10 | 16 room / climate zones |
| 33 | Zone valve bitmask | 16 heating circuit valves packed into WORD |
| 34-38 | Manifold pressures x100 | 5 manifolds |
| 40-71 | Lighting base levels | 32 lighting zones |
| 72-91 | Blinds positions | 20 blinds |
| 92-94 | Socket bitmasks | 36 sockets packed into 3 WORDs |
| 100-102 | 2FA request/code | Reserved auth range |

## Stabilization Fixes

- Removed legacy ARRAY[1..8] heating circuit gateway interface.
- Replaced fixed 8 loops with GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS.
- Restricted CMD_SET_TEMP target_zone to heating circuits only.
- Moved blinds registers from 60-79 to 72-91 to avoid collision with lighting 40-71.
- Moved socket registers from 80-82 to 92-94 to avoid collision with blinds.

## Remaining Notes

- Register 39 is intentionally unused as a gap after manifold pressure range.
- Register range 95-99 is intentionally reserved as a gap before 2FA.
- Future Modbus additions must update this document in the same commit as code changes.
