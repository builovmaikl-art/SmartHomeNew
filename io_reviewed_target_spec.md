# Reviewed target IO specification

## Purpose
- This document captures the owner-reviewed target architecture for IO optimization.
- It separates the currently declared PLC physical IO from the proposed bus-centric architecture.
- Source traceability caveat: in this environment the referenced `ТЗ .txt` file is still not visible in the repository, so this target is based on `result.txt` + latest owner corrections from chat and must be reconciled with the attached TЗ once it appears on disk.

## Baseline currently declared in project
- Baseline from `io_full_spec.md`:
  - **DI = 111**
  - **DO = 56**
  - **AI = 92**
  - **AO = 15**

## Approved optimization directions

| Direction | Current implementation assumption | Target architecture | IO effect |
|---|---|---|---|
| Boiler integration | Physical boiler channels: `DO_Boiler_Enable`, `AO_Boiler_Setpoint`, `AI_Boiler_Modulation`, `AI_Boiler_Flame_Status`, `DI_Boiler_Error` | Cascade BAXI Luna Platinum+ 24 (`1+1`) via OpenTherm gateway | `DO -2`, `AO -2`, `AI -2`, `DI -4` |
| Room climate sensing | Per-room physical channels for `AI_Room_Temps`, `AI_Room_Hum`, `AI_Room_CO2`, `DI_Motion_Sensors` | RS-485 Modbus multisensors in rooms (bus topology) | `AI -37`, `DI -16` |
| Light/socket switches | Physical star wiring `DI_Lighting_Switches` + `DI_Socket_Switches` | Modbus/KNX wall panels on bus | `DI -32` |
| Flood sensors | `DI_Flood_Sensors = 12` | Only wet zones | `DI -7` (to 5 sensors) |
| Socket actuators | `DO_Sockets = 16` | Group control by room, 12 groups | `DO -4` |
| Water inlet valves | Two close commands for inlet valves | One building inlet valve | `DO -1` |
| Audible alarms | Separate `DO_Gas_Siren`, `DO_Fire_Siren`, `DO_Security_Siren` | One common sounder | `DO -2` |
| Pump current feedback | `AI_Manifold_Currents = 5` | Remove CT analog channels; use smart pumps (PWM/Modbus) or optional DI pressure relays | `AI -5` (base target) |
| Water valve current #2 | `AI_Water_Valve_36_Current` | Removed together with second inlet valve | `AI -1` |

## Target physical IO after optimization
Applying all approved reductions above (base option with smart pumps, no extra DI pressure relays):

- **DI: 52**
  - `111 - 4 - 16 - 32 - 7 = 52`
- **DO: 47**
  - `56 - 2 - 4 - 1 - 2 = 47`
- **AI: 47**
  - `92 - 2 - 37 - 5 - 1 = 47`
- **AO: 13**
  - `15 - 2 = 13`

### Alternative for pumps (if DI pressure relays are used)
- Add `+5 DI` for pump proof/flow relays.
- Then DI becomes **57** instead of 52.

## Capacity implication

### Medium-density remote IO assumption
- 16 DI / module
- 16 DO / module
- 8 AI / module
- 4 AO / module

Required modules for target base option (52/47/47/13):
- DI: `ceil(52 / 16) = 4`
- DO: `ceil(47 / 16) = 3`
- AI: `ceil(47 / 8) = 6`
- AO: `ceil(13 / 4) = 4`
- **Total: 17 modules**

### Dense remote IO assumption
- 32 DI / module
- 32 DO / module
- 16 AI / module
- 8 AO / module

Required modules for target base option (52/47/47/13):
- DI: `ceil(52 / 32) = 2`
- DO: `ceil(47 / 32) = 2`
- AI: `ceil(47 / 16) = 3`
- AO: `ceil(13 / 8) = 2`
- **Total: 9 modules**

## Practical conclusion
- The bus-centric strategy (OpenTherm + RS-485 multisensors + bus switches/panels) is the most elegant way to remove the star-wiring bottleneck and expensive analog room IO.
- With dense modules, the target can fit into the existing logical budget of 10 modules; with medium-density modules, it still exceeds the budget.
- Final BOM should therefore lock module family first (dense vs medium-density) and then freeze a per-cabinet allocation table.
