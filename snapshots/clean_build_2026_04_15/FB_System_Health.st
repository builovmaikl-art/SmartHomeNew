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
END_VAR

VO_Sensor_Fault := VI_Sensor_Fault;
VO_IO_Fault := VI_IO_Offline;
VO_Comm_Fault := VI_Comm_Fault;
VO_Subsystem_Degraded := VI_Subsystem_Fault;

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

ELSIF VI_IO_Offline THEN
    VO_System_Severity := E_System_Severity.SEV_DEGRADED;
    VO_Root_Cause := E_System_Root_Cause.ROOT_IO_OFFLINE;
    VO_First_Fault_Active := TRUE;
    VO_First_Fault_Type := 1;

ELSIF VI_Comm_Fault THEN
    VO_System_Severity := E_System_Severity.SEV_DEGRADED;
    VO_Root_Cause := E_System_Root_Cause.ROOT_COMM_FAULT;
    VO_First_Fault_Active := TRUE;
    VO_First_Fault_Type := 3;

ELSIF VI_Sensor_Fault THEN
    VO_System_Severity := E_System_Severity.SEV_DEGRADED;
    VO_Root_Cause := E_System_Root_Cause.ROOT_SENSOR_FAULT;
    VO_First_Fault_Active := TRUE;
    VO_First_Fault_Type := 2;

ELSIF VI_Subsystem_Fault THEN
    VO_System_Severity := E_System_Severity.SEV_DEGRADED;
    VO_Root_Cause := E_System_Root_Cause.ROOT_SUBSYSTEM_FAULT;
    VO_First_Fault_Active := TRUE;
    VO_First_Fault_Type := 4;
END_IF;
// >>> BULK_SYNC_ANCHOR: FB_System_Health <<<
