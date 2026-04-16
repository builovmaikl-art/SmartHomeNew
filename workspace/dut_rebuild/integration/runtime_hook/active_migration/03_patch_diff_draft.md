# Patch Diff Draft (conceptual)

FOR L_i := 1 TO ... DO

    // NEW (safe layer)
    fbCompat[L_i](VI_Rule_Legacy := VI_Rules[L_i]);

    // EXISTING CODE CONTINUES
    IF VI_Rules[L_i].Enabled THEN
        ...

Notes:
- no change to VO_Actions in phase 1
- adapter only validates + prepares future data
