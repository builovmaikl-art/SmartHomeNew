FUNCTION_BLOCK FB_Lifetime_Manager
VAR_INPUT
    VI_System_Time_MS : UDINT;
    VI_Device_Active  : BOOL;
    VI_Device_ID      : BYTE;
    VI_Nominal_Hours : REAL;
END_VAR

VAR_IN_OUT
    VIO_Status : ST_Lifetime_Status;
END_VAR

VAR
    L_Last_Time : UDINT;
    L_Prev_State : BOOL;
    L_Delta_MS : UDINT;
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

// === BASIC FLAGS ===
VIO_Status.device_id := VI_Device_ID;
VIO_Status.last_calc_timestamp := VI_System_Time_MS;

END_FUNCTION_BLOCK
