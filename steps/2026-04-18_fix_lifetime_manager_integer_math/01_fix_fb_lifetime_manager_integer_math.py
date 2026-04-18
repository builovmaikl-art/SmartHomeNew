from pathlib import Path

path = Path("FB_Lifetime_Manager.st")
text = path.read_text(encoding="utf-8")

old_var = """VAR
    L_Last_Time : UDINT;
    L_Prev_State : BOOL;
    L_Delta_MS : UDINT;
END_VAR
"""

new_var = """VAR
    L_Last_Time : UDINT;
    L_Prev_State : BOOL;
    L_Delta_MS : UDINT;
    L_Runtime_Accum_MS : UDINT;
    L_Nominal_Hours_UDINT : UDINT;
    L_Remaining_Percent_UDINT : UDINT;
END_VAR
"""

if old_var not in text:
    raise SystemExit("VAR block not found in FB_Lifetime_Manager.st")

text = text.replace(old_var, new_var, 1)

old_runtime_and_estimation = """// === RUNTIME ACCUMULATION ===
IF VI_Device_Active THEN
    VIO_Status.runtime_hours := VIO_Status.runtime_hours + (L_Delta_MS / 3600000);
END_IF;

// === BASIC LIFETIME ESTIMATION ===
IF VI_Nominal_Hours > 0.0 THEN
    IF VIO_Status.runtime_hours >= VI_Nominal_Hours THEN
        VIO_Status.remaining_hours := 0.0;
        VIO_Status.remaining_percent := 0.0;
    ELSE
        VIO_Status.remaining_hours := VI_Nominal_Hours - VIO_Status.runtime_hours;
        VIO_Status.remaining_percent := (VIO_Status.remaining_hours / VI_Nominal_Hours) * 100.0;
    END_IF;
ELSE
    VIO_Status.remaining_hours := 0.0;
    VIO_Status.remaining_percent := 0.0;
END_IF;

VIO_Status.maintenance_required := VIO_Status.remaining_percent <= 20.0;
"""

new_runtime_and_estimation = """// === RUNTIME ACCUMULATION ===
IF VI_Device_Active THEN
    L_Runtime_Accum_MS := L_Runtime_Accum_MS + L_Delta_MS;

    WHILE L_Runtime_Accum_MS >= 3600000 DO
        VIO_Status.runtime_hours := VIO_Status.runtime_hours + 1;
        L_Runtime_Accum_MS := L_Runtime_Accum_MS - 3600000;
    END_WHILE;
END_IF;

// === BASIC LIFETIME ESTIMATION ===
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

if old_runtime_and_estimation not in text:
    raise SystemExit("Runtime/estimation block not found in FB_Lifetime_Manager.st")

text = text.replace(old_runtime_and_estimation, new_runtime_and_estimation, 1)

path.write_text(text, encoding="utf-8")
print("OK: fixed FB_Lifetime_Manager to use integer math and ms accumulator")
