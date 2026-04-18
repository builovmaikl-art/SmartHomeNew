FUNCTION_BLOCK FB_Lifetime_Manager
VAR_INPUT
    VI_System_Time_MS : UDINT;
    VI_Device_Active  : BOOL;
    VI_Device_ID      : BYTE;
    VI_Nominal_Hours : UDINT;
END_VAR

VAR_IN_OUT
    VIO_Status : ST_Lifetime_Status;
END_VAR

VAR
    L_Last_Time : UDINT;
    L_Prev_State : BOOL;
    L_Delta_MS : UDINT;
    L_Runtime_Accum_MS : UDINT;
    L_Remaining_Percent_UDINT : UDINT;
END_VAR

// === DELTA TIME ===
IF VI_System_Time_MS >= L_Last_Time THEN
    L_Delta_MS := VI_System_Time_MS - L_Last_Time;
ELSE
    // overflow
    L_Delta_MS := (4294967295 - L_Last_Time) + VI_System_Time_MS + 1;
END_IF;

L_Last_Time := VI_System_Time_MS;

// === START COUNT ===
IF VI_Device_Active AND NOT L_Prev_State THEN
    VIO_Status.start_count := VIO_Status.start_count + 1;
END_IF;

L_Prev_State := VI_Device_Active;

// === RUNTIME ACCUMULATION ===
IF VI_Device_Active THEN
    L_Runtime_Accum_MS := L_Runtime_Accum_MS + L_Delta_MS;

    WHILE L_Runtime_Accum_MS >= 3600000 DO
        VIO_Status.runtime_hours := VIO_Status.runtime_hours + 1;
        L_Runtime_Accum_MS := L_Runtime_Accum_MS - 3600000;
    END_WHILE;
END_IF;

// === BASIC LIFETIME ESTIMATION ===
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

// === BASIC FLAGS ===
VIO_Status.device_id := VI_Device_ID;
VIO_Status.last_calc_timestamp := VI_System_Time_MS;

END_FUNCTION_BLOCK
