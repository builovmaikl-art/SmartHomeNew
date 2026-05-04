FUNCTION_BLOCK FB_System_Health
VAR_INPUT
    VI_Smoke_Detected      : BOOL;
    VI_Gas_Detected        : BOOL;
    VI_CO_Warning_Level    : BOOL;
    VI_CO_Alarm_Level      : BOOL;
    VI_Leak_Detected       : BOOL;

    VI_Sensor_Fault        : BOOL := FALSE;
    VI_IO_Offline          : BOOL := FALSE;
    VI_Comm_Fault          : BOOL := FALSE;
    VI_Watchdog_Fault      : BOOL := FALSE;
    VI_Subsystem_Fault     : BOOL := FALSE;
END_VAR

VAR
    L_IO_Fault_Assert_Count        : UINT;
    L_IO_Fault_Clear_Count         : UINT;
    L_IO_Fault_Stable              : BOOL;

    L_Comm_Fault_Assert_Count      : UINT;
    L_Comm_Fault_Clear_Count       : UINT;
    L_Comm_Fault_Stable            : BOOL;

    L_Sensor_Fault_Assert_Count    : UINT;
    L_Sensor_Fault_Clear_Count     : UINT;
    L_Sensor_Fault_Stable          : BOOL;

    L_Subsystem_Assert_Count       : UINT;
    L_Subsystem_Clear_Count        : UINT;
    L_Subsystem_Fault_Stable       : BOOL;

    L_IO_Fault_Prev                : BOOL;
    L_Comm_Fault_Prev              : BOOL;
    L_Sensor_Fault_Prev            : BOOL;
    L_Subsystem_Fault_Prev         : BOOL;
    L_Watchdog_Fault_Prev          : BOOL;
END_VAR

VAR CONSTANT
    C_HEALTH_DEBOUNCE_CYCLES       : UINT := 3;
END_VAR

VAR_OUTPUT
    VO_System_Severity     : E_System_Severity;
    VO_Root_Cause          : E_System_Root_Cause;

    // compatibility outputs for existing orchestration
    VO_Sensor_Fault        : BOOL;
    VO_IO_Fault            : BOOL;
    VO_Comm_Fault          : BOOL;
    VO_Subsystem_Degraded  : BOOL;

    VO_First_Fault_Active  : BOOL;
    VO_First_Fault_Type    : INT;
    VO_First_Fault_Source  : INT;

    VO_IO_Fault_Count          : UDINT;
    VO_Comm_Fault_Count        : UDINT;
    VO_Sensor_Fault_Count      : UDINT;
    VO_Subsystem_Fault_Count   : UDINT;
    VO_Watchdog_Fault_Count    : UDINT;
END_VAR

// Debounce non-critical diagnostics: require 3 stable cycles to assert/clear
IF VI_IO_Offline THEN
    L_IO_Fault_Clear_Count := 0;
    IF L_IO_Fault_Assert_Count < C_HEALTH_DEBOUNCE_CYCLES THEN
        L_IO_Fault_Assert_Count := L_IO_Fault_Assert_Count + 1;
    END_IF;
    IF L_IO_Fault_Assert_Count >= C_HEALTH_DEBOUNCE_CYCLES THEN
        L_IO_Fault_Stable := TRUE;
    END_IF;
ELSE
    L_IO_Fault_Assert_Count := 0;
    IF L_IO_Fault_Clear_Count < C_HEALTH_DEBOUNCE_CYCLES THEN
        L_IO_Fault_Clear_Count := L_IO_Fault_Clear_Count + 1;
    END_IF;
    IF L_IO_Fault_Clear_Count >= C_HEALTH_DEBOUNCE_CYCLES THEN
        L_IO_Fault_Stable := FALSE;
    END_IF;
END_IF;

IF VI_Comm_Fault THEN
    L_Comm_Fault_Clear_Count := 0;
    IF L_Comm_Fault_Assert_Count < C_HEALTH_DEBOUNCE_CYCLES THEN
        L_Comm_Fault_Assert_Count := L_Comm_Fault_Assert_Count + 1;
    END_IF;
    IF L_Comm_Fault_Assert_Count >= C_HEALTH_DEBOUNCE_CYCLES THEN
        L_Comm_Fault_Stable := TRUE;
    END_IF;
ELSE
    L_Comm_Fault_Assert_Count := 0;
    IF L_Comm_Fault_Clear_Count < C_HEALTH_DEBOUNCE_CYCLES THEN
        L_Comm_Fault_Clear_Count := L_Comm_Fault_Clear_Count + 1;
    END_IF;
    IF L_Comm_Fault_Clear_Count >= C_HEALTH_DEBOUNCE_CYCLES THEN
        L_Comm_Fault_Stable := FALSE;
    END_IF;
END_IF;

IF VI_Sensor_Fault THEN
    L_Sensor_Fault_Clear_Count := 0;
    IF L_Sensor_Fault_Assert_Count < C_HEALTH_DEBOUNCE_CYCLES THEN
        L_Sensor_Fault_Assert_Count := L_Sensor_Fault_Assert_Count + 1;
    END_IF;
    IF L_Sensor_Fault_Assert_Count >= C_HEALTH_DEBOUNCE_CYCLES THEN
        L_Sensor_Fault_Stable := TRUE;
    END_IF;
ELSE
    L_Sensor_Fault_Assert_Count := 0;
    IF L_Sensor_Fault_Clear_Count < C_HEALTH_DEBOUNCE_CYCLES THEN
        L_Sensor_Fault_Clear_Count := L_Sensor_Fault_Clear_Count + 1;
    END_IF;
    IF L_Sensor_Fault_Clear_Count >= C_HEALTH_DEBOUNCE_CYCLES THEN
        L_Sensor_Fault_Stable := FALSE;
    END_IF;
END_IF;

IF VI_Subsystem_Fault THEN
    L_Subsystem_Clear_Count := 0;
    IF L_Subsystem_Assert_Count < C_HEALTH_DEBOUNCE_CYCLES THEN
        L_Subsystem_Assert_Count := L_Subsystem_Assert_Count + 1;
    END_IF;
    IF L_Subsystem_Assert_Count >= C_HEALTH_DEBOUNCE_CYCLES THEN
        L_Subsystem_Fault_Stable := TRUE;
    END_IF;
ELSE
    L_Subsystem_Assert_Count := 0;
    IF L_Subsystem_Clear_Count < C_HEALTH_DEBOUNCE_CYCLES THEN
        L_Subsystem_Clear_Count := L_Subsystem_Clear_Count + 1;
    END_IF;
    IF L_Subsystem_Clear_Count >= C_HEALTH_DEBOUNCE_CYCLES THEN
        L_Subsystem_Fault_Stable := FALSE;
    END_IF;
END_IF;

// Count confirmed fault events on rising edge of stable/critical conditions
IF L_IO_Fault_Stable AND NOT L_IO_Fault_Prev THEN
    VO_IO_Fault_Count := VO_IO_Fault_Count + 1;
END_IF;
L_IO_Fault_Prev := L_IO_Fault_Stable;

IF L_Comm_Fault_Stable AND NOT L_Comm_Fault_Prev THEN
    VO_Comm_Fault_Count := VO_Comm_Fault_Count + 1;
END_IF;
L_Comm_Fault_Prev := L_Comm_Fault_Stable;

IF L_Sensor_Fault_Stable AND NOT L_Sensor_Fault_Prev THEN
    VO_Sensor_Fault_Count := VO_Sensor_Fault_Count + 1;
END_IF;
L_Sensor_Fault_Prev := L_Sensor_Fault_Stable;

IF L_Subsystem_Fault_Stable AND NOT L_Subsystem_Fault_Prev THEN
    VO_Subsystem_Fault_Count := VO_Subsystem_Fault_Count + 1;
END_IF;
L_Subsystem_Fault_Prev := L_Subsystem_Fault_Stable;

IF VI_Watchdog_Fault AND NOT L_Watchdog_Fault_Prev THEN
    VO_Watchdog_Fault_Count := VO_Watchdog_Fault_Count + 1;
END_IF;
L_Watchdog_Fault_Prev := VI_Watchdog_Fault;

VO_Sensor_Fault := L_Sensor_Fault_Stable;
VO_IO_Fault := L_IO_Fault_Stable;
VO_Comm_Fault := L_Comm_Fault_Stable;
VO_Subsystem_Degraded := L_Subsystem_Fault_Stable;

VO_System_Severity := E_System_Severity.SEV_NORMAL;
VO_Root_Cause := E_System_Root_Cause.ROOT_NONE;
VO_First_Fault_Active := FALSE;
VO_First_Fault_Type := 0;
VO_First_Fault_Source := 0;

// Priority: FIRE > GAS > CO > WATER > diagnostics
IF VI_Smoke_Detected THEN
    VO_System_Severity := E_System_Severity.SEV_CRITICAL;
    VO_Root_Cause := E_System_Root_Cause.ROOT_FIRE;
    VO_First_Fault_Active := TRUE;
    VO_First_Fault_Type := 5;

ELSIF VI_Gas_Detected THEN
    VO_System_Severity := E_System_Severity.SEV_CRITICAL;
    VO_Root_Cause := E_System_Root_Cause.ROOT_GAS_LEAK;
    VO_First_Fault_Active := TRUE;
    VO_First_Fault_Type := 6;

ELSIF VI_CO_Alarm_Level THEN
    VO_System_Severity := E_System_Severity.SEV_CRITICAL;
    VO_Root_Cause := E_System_Root_Cause.ROOT_CO_CRITICAL;
    VO_First_Fault_Active := TRUE;
    VO_First_Fault_Type := 7;

ELSIF VI_CO_Warning_Level THEN
    VO_System_Severity := E_System_Severity.SEV_WARNING;
    VO_Root_Cause := E_System_Root_Cause.ROOT_CO_WARNING;
    VO_First_Fault_Active := TRUE;
    VO_First_Fault_Type := 7;

ELSIF VI_Leak_Detected THEN
    VO_System_Severity := E_System_Severity.SEV_WARNING;
    VO_Root_Cause := E_System_Root_Cause.ROOT_WATER_LEAK;
    VO_First_Fault_Active := TRUE;
    VO_First_Fault_Type := 8;

ELSIF VI_Watchdog_Fault THEN
    VO_System_Severity := E_System_Severity.SEV_CRITICAL;
    VO_Root_Cause := E_System_Root_Cause.ROOT_WATCHDOG_FAULT;
    VO_First_Fault_Active := TRUE;
    VO_First_Fault_Type := 9;

ELSIF L_IO_Fault_Stable THEN
    VO_System_Severity := E_System_Severity.SEV_DEGRADED;
    VO_Root_Cause := E_System_Root_Cause.ROOT_IO_OFFLINE;
    VO_First_Fault_Active := TRUE;
    VO_First_Fault_Type := 1;

ELSIF L_Comm_Fault_Stable THEN
    VO_System_Severity := E_System_Severity.SEV_DEGRADED;
    VO_Root_Cause := E_System_Root_Cause.ROOT_COMM_FAULT;
    VO_First_Fault_Active := TRUE;
    VO_First_Fault_Type := 3;

ELSIF L_Sensor_Fault_Stable THEN
    VO_System_Severity := E_System_Severity.SEV_DEGRADED;
    VO_Root_Cause := E_System_Root_Cause.ROOT_SENSOR_FAULT;
    VO_First_Fault_Active := TRUE;
    VO_First_Fault_Type := 2;

ELSIF L_Subsystem_Fault_Stable THEN
    VO_System_Severity := E_System_Severity.SEV_DEGRADED;
    VO_Root_Cause := E_System_Root_Cause.ROOT_SUBSYSTEM_FAULT;
    VO_First_Fault_Active := TRUE;
    VO_First_Fault_Type := 4;
END_IF;
// >>> BULK_SYNC_ANCHOR: FB_System_Health <<<
END_FUNCTION_BLOCK
