from pathlib import Path

path = Path("FB_Lifetime_Manager.st")
text = path.read_text(encoding="utf-8")

text = text.replace(
    "    VI_Nominal_Hours : REAL;",
    "    VI_Nominal_Hours : UDINT;"
)

old_var = """VAR
    L_Last_Time : UDINT;
    L_Prev_State : BOOL;
    L_Delta_MS : UDINT;
    L_Runtime_Accum_MS : UDINT;
    L_Nominal_Hours_UDINT : UDINT;
    L_Remaining_Percent_UDINT : UDINT;
END_VAR
"""

new_var = """VAR
    L_Last_Time : UDINT;
    L_Prev_State : BOOL;
    L_Delta_MS : UDINT;
    L_Runtime_Accum_MS : UDINT;
    L_Remaining_Percent_UDINT : UDINT;
END_VAR
"""

if old_var in text:
    text = text.replace(old_var, new_var, 1)

old_block = """// === BASIC LIFETIME ESTIMATION ===
L_Nominal_Hours_UDINT := REAL_TO_UDINT(VI_Nominal_Hours);

IF L_Nominal_Hours_UDINT > 0 THEN
    IF VIO_Status.runtime_hours >= L_Nominal_Hours_UDINT THEN
        VIO_Status.remaining_hours := 0;
        VIO_Status.remaining_percent := 0;
    ELSE
        VIO_Status.remaining_hours := L_Nominal_Hours_UDINT - VIO_Status.runtime_hours;
        L_Remaining_Percent_UDINT := (VIO_Status.remaining_hours * 100) / L_Nominal_Hours_UDINT;

        IF L_Remaining_Percent_UDINT > 100 THEN
            L_Remaining_Percent_UDINT := 100;
        END_IF;

        VIO_Status.remaining_percent := UDINT_TO_BYTE(L_Remaining_Percent_UDINT);
    END_IF;
ELSE
    VIO_Status.remaining_hours := 0;
    VIO_Status.remaining_percent := 0;
END_IF;

VIO_Status.maintenance_required := VIO_Status.remaining_percent <= 20;
"""

new_block = """// === BASIC LIFETIME ESTIMATION ===
IF VI_Nominal_Hours > 0 THEN
    IF VIO_Status.runtime_hours >= VI_Nominal_Hours THEN
        VIO_Status.remaining_hours := 0;
        VIO_Status.remaining_percent := 0;
    ELSE
        VIO_Status.remaining_hours := VI_Nominal_Hours - VIO_Status.runtime_hours;
        L_Remaining_Percent_UDINT := (VIO_Status.remaining_hours * 100) / VI_Nominal_Hours;

        IF L_Remaining_Percent_UDINT > 100 THEN
            L_Remaining_Percent_UDINT := 100;
        END_IF;

        VIO_Status.remaining_percent := UDINT_TO_BYTE(L_Remaining_Percent_UDINT);
    END_IF;
ELSE
    VIO_Status.remaining_hours := 0;
    VIO_Status.remaining_percent := 0;
END_IF;

VIO_Status.maintenance_required := VIO_Status.remaining_percent <= GVL_Lifetime.G_Maintenance_Threshold_Percent;
"""

if old_block not in text:
    raise SystemExit("Expected lifetime estimation block not found in FB_Lifetime_Manager.st")

text = text.replace(old_block, new_block, 1)

path.write_text(text, encoding="utf-8")
print("OK: switched FB_Lifetime_Manager nominal-hours input to UDINT")
