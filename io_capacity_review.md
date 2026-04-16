# PLC / IO capacity review

## Scope
- Recounted declared physical IO channels from the hardware IO declaration block in `result.txt`.
- Checked whether the current project budget of `C_MAX_MODULES = 10` is sufficient.
- Reviewed runtime watchdog coverage for IO modules.

## Counting rules
- Counted declared field channels from the `GVL_IO`-style hardware block.
- Classified `AI_Boiler_Flame_Status` as a **discrete input**, even though its name starts with `AI_`, because the declaration/comment describe a boolean flame confirmation signal.
- Included heartbeat/status signals for partner PLC and IO-module watchdogs because they still consume physical channels.

## Recounted channel totals
- **DI:** 111
- **DO:** 56
- **AI:** 92
- **AO:** 15

## Sufficiency check against module budget
Current project constant:
- `C_MAX_MODULES = 10`

Two reference assumptions were used because the repository does not define exact module part numbers:

### Scenario A — common medium-density remote IO
- 16 DI per module
- 16 DO per module
- 8 AI per module
- 4 AO per module

Required modules:
- DI: `ceil(111 / 16) = 7`
- DO: `ceil(56 / 16) = 4`
- AI: `ceil(92 / 8) = 12`
- AO: `ceil(15 / 4) = 4`
- **Total: 27 modules**

### Scenario B — dense remote IO
- 32 DI per module
- 32 DO per module
- 16 AI per module
- 8 AO per module

Required modules:
- DI: `ceil(111 / 32) = 4`
- DO: `ceil(56 / 32) = 2`
- AI: `ceil(92 / 16) = 6`
- AO: `ceil(15 / 8) = 2`
- **Total: 14 modules**

## Conclusion
- Under both a medium-density and a dense-module assumption, the current logical budget of **10 IO modules is not sufficient** for the declared IO volume.
- Even the denser estimate requires **14 modules**, which is above the configured `C_MAX_MODULES`.
- Therefore the project currently has an **IO-capacity mismatch** between declared signals and the module budget.

## Additional implementation gap
- Runtime watchdog monitoring is currently wired only for **module 1** and **module 2**.
- This means the project not only underestimates required module count, but also does not supervise the full module set implied by the declared IO list.

## Recommended next steps
1. Freeze the real hardware BOM (exact PLC + remote IO module SKUs).
2. Replace the generic `C_MAX_MODULES = 10` assumption with a counted module plan per DI/DO/AI/AO family.
3. Extend watchdog wiring from 2 modules to the full installed module set.
4. Split the IO declaration into a per-cabinet / per-module allocation table so sufficiency can be validated automatically.

## Updated optimization scenario (owner-approved bus architecture)
- See `io_reviewed_target_spec.md` for the refined target with OpenTherm boilers and RS-485/Modbus room devices.
- Target physical channels in that scenario (base option):
  - DI: 52
  - DO: 47
  - AI: 47
  - AO: 13
- Module estimate for that target:
  - medium-density (16DI/16DO/8AI/4AO): 17 modules
  - dense (32DI/32DO/16AI/8AO): 9 modules

