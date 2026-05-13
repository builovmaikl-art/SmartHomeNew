PROGRAM PRG_System_Diagnostics_Ext
VAR
    L_Error_Heating : BOOL;
    L_Error_Safety : BOOL;
    L_Error_IO : BOOL;

    L_Delta_Time : REAL;
    L_Now : UDINT;
    L_Last : UDINT;

    // cycle stats
    L_Cycle_MS : UDINT;
    L_Prev_Overrun : BOOL;
    L_Prev_Critical : BOOL;
    fbLog : FB_LogEvent;
END_VAR

L_Now := GVL_TIME_SERVICE.G_Now_MS;
L_Last := GVL_DIAGNOSTICS_EXT.G_Last_Update_Time;

// ===============================
// CYCLE INTERVAL MEASUREMENT
// ===============================
IF L_Last = 0 THEN
    L_Cycle_MS := GVL_DIAGNOSTICS_EXT.G_Cycle_Expected_MS;
ELSE
    IF L_Now >= L_Last THEN
        L_Cycle_MS := L_Now - L_Last;
    ELSE
        L_Cycle_MS := (4294967295 - L_Last) + L_Now + 1;
    END_IF;
END_IF;

GVL_DIAGNOSTICS_EXT.G_Last_Update_Time := L_Now;
GVL_DIAGNOSTICS_EXT.G_Cycle_Last_MS := L_Cycle_MS;

// min/max
IF (GVL_DIAGNOSTICS_EXT.G_Cycle_Min_MS = 0) OR (L_Cycle_MS < GVL_DIAGNOSTICS_EXT.G_Cycle_Min_MS) THEN
    GVL_DIAGNOSTICS_EXT.G_Cycle_Min_MS := L_Cycle_MS;
END_IF;

IF L_Cycle_MS > GVL_DIAGNOSTICS_EXT.G_Cycle_Max_MS THEN
    GVL_DIAGNOSTICS_EXT.G_Cycle_Max_MS := L_Cycle_MS;
END_IF;

// average (incremental)
GVL_DIAGNOSTICS_EXT.G_Cycle_Sample_Count := GVL_DIAGNOSTICS_EXT.G_Cycle_Sample_Count + 1;
GVL_DIAGNOSTICS_EXT.G_Cycle_Avg_MS :=
    GVL_DIAGNOSTICS_EXT.G_Cycle_Avg_MS +
    (UDINT_TO_REAL(L_Cycle_MS) - GVL_DIAGNOSTICS_EXT.G_Cycle_Avg_MS) /
    UDINT_TO_REAL(GVL_DIAGNOSTICS_EXT.G_Cycle_Sample_Count);

// ===============================
// OVERRUN / CRITICAL DETECTION
// ===============================
GVL_DIAGNOSTICS_EXT.G_Cycle_Overrun_Active := (L_Cycle_MS > GVL_DIAGNOSTICS_EXT.G_Cycle_Warning_MS);
GVL_DIAGNOSTICS_EXT.G_Cycle_Critical_Active := (L_Cycle_MS > GVL_DIAGNOSTICS_EXT.G_Cycle_Critical_MS);

IF GVL_DIAGNOSTICS_EXT.G_Cycle_Overrun_Active THEN
    GVL_DIAGNOSTICS_EXT.G_Cycle_Overrun_Count := GVL_DIAGNOSTICS_EXT.G_Cycle_Overrun_Count + 1;
    GVL_DIAGNOSTICS_EXT.G_Cycle_Last_Overrun_MS := L_Cycle_MS;
    GVL_DIAGNOSTICS_EXT.G_Cycle_Last_Overrun_Time_MS := L_Now;
END_IF;

IF GVL_DIAGNOSTICS_EXT.G_Cycle_Critical_Active THEN
    GVL_DIAGNOSTICS_EXT.G_Cycle_Critical_Count := GVL_DIAGNOSTICS_EXT.G_Cycle_Critical_Count + 1;
END_IF;

// edge logging
IF GVL_DIAGNOSTICS_EXT.G_Cycle_Overrun_Active AND NOT L_Prev_Overrun THEN
    fbLog(
        VI_Event_Type := 2001,
        VI_Timestamp := L_Now,
        VI_Param1 := L_Cycle_MS,
        VI_Param2 := GVL_DIAGNOSTICS_EXT.G_Cycle_Overrun_Count
    );
END_IF;

IF GVL_DIAGNOSTICS_EXT.G_Cycle_Critical_Active AND NOT L_Prev_Critical THEN
    fbLog(
        VI_Event_Type := 2002,
        VI_Timestamp := L_Now,
        VI_Param1 := L_Cycle_MS,
        VI_Param2 := GVL_DIAGNOSTICS_EXT.G_Cycle_Critical_Count
    );
END_IF;

L_Prev_Overrun := GVL_DIAGNOSTICS_EXT.G_Cycle_Overrun_Active;
L_Prev_Critical := GVL_DIAGNOSTICS_EXT.G_Cycle_Critical_Active;

// ===============================
// EXISTING HEALTH LOGIC
// ===============================
IF L_Last = 0 THEN
    L_Delta_Time := 0.1;
ELSE
    L_Delta_Time := UDINT_TO_REAL(L_Cycle_MS) / 1000.0;
END_IF;

L_Error_Heating := GVL_STATE.G_Heating_Subsystem_Degraded;

// Extended diagnostics must use authoritative safety truth and latches,
// not stale projected GVL_STATE.G_Safety_*_Alarm compatibility fields.
L_Error_Safety :=
    GVL_HEALTH_BRIDGE.G_Gas_Detected OR
    GVL_HEALTH_BRIDGE.G_CO_Alarm_Level OR
    GVL_HEALTH_BRIDGE.G_Leak_Detected OR
    GVL_HEALTH_BRIDGE.G_Smoke_Detected OR
    GVL_STATE.G_Safety_Gas_Latched OR
    GVL_STATE.G_Safety_Leak_Latched OR
    GVL_STATE.G_Safety_Smoke_Latched;

L_Error_IO := GVL_STATE.G_Heating_IO_Fault;

IF L_Error_Heating THEN
    GVL_DIAGNOSTICS_EXT.G_Error_Count_Heating := GVL_DIAGNOSTICS_EXT.G_Error_Count_Heating + 1;
    GVL_DIAGNOSTICS_EXT.G_Last_Error_Time_Heating := L_Now;
    GVL_DIAGNOSTICS_EXT.G_Health_Heating := GVL_DIAGNOSTICS_EXT.G_Health_Heating - (0.5 * L_Delta_Time);
ELSE
    GVL_DIAGNOSTICS_EXT.G_Health_Heating := GVL_DIAGNOSTICS_EXT.G_Health_Heating + (0.1 * L_Delta_Time);
END_IF;

IF L_Error_Safety THEN
    GVL_DIAGNOSTICS_EXT.G_Error_Count_Safety := GVL_DIAGNOSTICS_EXT.G_Error_Count_Safety + 1;
    GVL_DIAGNOSTICS_EXT.G_Last_Error_Time_Safety := L_Now;
    GVL_DIAGNOSTICS_EXT.G_Health_Safety := GVL_DIAGNOSTICS_EXT.G_Health_Safety - (1.0 * L_Delta_Time);
ELSE
    GVL_DIAGNOSTICS_EXT.G_Health_Safety := GVL_DIAGNOSTICS_EXT.G_Health_Safety + (0.2 * L_Delta_Time);
END_IF;

IF L_Error_IO THEN
    GVL_DIAGNOSTICS_EXT.G_Error_Count_IO := GVL_DIAGNOSTICS_EXT.G_Error_Count_IO + 1;
    GVL_DIAGNOSTICS_EXT.G_Last_Error_Time_IO := L_Now;
    GVL_DIAGNOSTICS_EXT.G_Health_IO := GVL_DIAGNOSTICS_EXT.G_Health_IO - (0.5 * L_Delta_Time);
ELSE
    GVL_DIAGNOSTICS_EXT.G_Health_IO := GVL_DIAGNOSTICS_EXT.G_Health_IO + (0.1 * L_Delta_Time);
END_IF;

// clamp
IF GVL_DIAGNOSTICS_EXT.G_Health_Heating < 0.0 THEN GVL_DIAGNOSTICS_EXT.G_Health_Heating := 0.0; END_IF;
IF GVL_DIAGNOSTICS_EXT.G_Health_Heating > 1.0 THEN GVL_DIAGNOSTICS_EXT.G_Health_Heating := 1.0; END_IF;

IF GVL_DIAGNOSTICS_EXT.G_Health_Safety < 0.0 THEN GVL_DIAGNOSTICS_EXT.G_Health_Safety := 0.0; END_IF;
IF GVL_DIAGNOSTICS_EXT.G_Health_Safety > 1.0 THEN GVL_DIAGNOSTICS_EXT.G_Health_Safety := 1.0; END_IF;

IF GVL_DIAGNOSTICS_EXT.G_Health_IO < 0.0 THEN GVL_DIAGNOSTICS_EXT.G_Health_IO := 0.0; END_IF;
IF GVL_DIAGNOSTICS_EXT.G_Health_IO > 1.0 THEN GVL_DIAGNOSTICS_EXT.G_Health_IO := 1.0; END_IF;

END_PROGRAM
