PROGRAM PRG_System_Diagnostics_Ext
VAR
    L_Error_Heating : BOOL;
    L_Error_Safety : BOOL;
    L_Error_IO : BOOL;

    L_Delta_Time : REAL;
    L_Now : UDINT;
    L_Last : UDINT;
END_VAR

// Time delta (ms → seconds)
L_Now := GVL_TIME_SERVICE.G_Now_MS;
L_Last := GVL_DIAGNOSTICS_EXT.G_Last_Update_Time;

IF L_Last = 0 THEN
    L_Delta_Time := 0.1; // fallback
ELSE
    L_Delta_Time := REAL(L_Now - L_Last) / 1000.0;
END_IF;

GVL_DIAGNOSTICS_EXT.G_Last_Update_Time := L_Now;

// --- Detect errors ---
L_Error_Heating := GVL_STATE.G_Heating_Subsystem_Degraded;
L_Error_Safety := GVL_STATE.G_Safety_Gas_Alarm OR GVL_STATE.G_Safety_Leak_Alarm OR GVL_STATE.G_Safety_Smoke_Alarm;
L_Error_IO := GVL_STATE.G_Heating_IO_Fault;

// --- Heating health (decay model) ---
IF L_Error_Heating THEN
    GVL_DIAGNOSTICS_EXT.G_Error_Count_Heating := GVL_DIAGNOSTICS_EXT.G_Error_Count_Heating + 1;
    GVL_DIAGNOSTICS_EXT.G_Last_Error_Time_Heating := L_Now;
    GVL_DIAGNOSTICS_EXT.G_Health_Heating := GVL_DIAGNOSTICS_EXT.G_Health_Heating - (0.5 * L_Delta_Time);
ELSE
    GVL_DIAGNOSTICS_EXT.G_Health_Heating := GVL_DIAGNOSTICS_EXT.G_Health_Heating + (0.1 * L_Delta_Time);
END_IF;

// --- Safety health ---
IF L_Error_Safety THEN
    GVL_DIAGNOSTICS_EXT.G_Error_Count_Safety := GVL_DIAGNOSTICS_EXT.G_Error_Count_Safety + 1;
    GVL_DIAGNOSTICS_EXT.G_Last_Error_Time_Safety := L_Now;
    GVL_DIAGNOSTICS_EXT.G_Health_Safety := GVL_DIAGNOSTICS_EXT.G_Health_Safety - (1.0 * L_Delta_Time);
ELSE
    GVL_DIAGNOSTICS_EXT.G_Health_Safety := GVL_DIAGNOSTICS_EXT.G_Health_Safety + (0.2 * L_Delta_Time);
END_IF;

// --- IO health ---
IF L_Error_IO THEN
    GVL_DIAGNOSTICS_EXT.G_Error_Count_IO := GVL_DIAGNOSTICS_EXT.G_Error_Count_IO + 1;
    GVL_DIAGNOSTICS_EXT.G_Last_Error_Time_IO := L_Now;
    GVL_DIAGNOSTICS_EXT.G_Health_IO := GVL_DIAGNOSTICS_EXT.G_Health_IO - (0.5 * L_Delta_Time);
ELSE
    GVL_DIAGNOSTICS_EXT.G_Health_IO := GVL_DIAGNOSTICS_EXT.G_Health_IO + (0.1 * L_Delta_Time);
END_IF;

// Clamp all
IF GVL_DIAGNOSTICS_EXT.G_Health_Heating < 0.0 THEN GVL_DIAGNOSTICS_EXT.G_Health_Heating := 0.0; END_IF;
IF GVL_DIAGNOSTICS_EXT.G_Health_Heating > 1.0 THEN GVL_DIAGNOSTICS_EXT.G_Health_Heating := 1.0; END_IF;

IF GVL_DIAGNOSTICS_EXT.G_Health_Safety < 0.0 THEN GVL_DIAGNOSTICS_EXT.G_Health_Safety := 0.0; END_IF;
IF GVL_DIAGNOSTICS_EXT.G_Health_Safety > 1.0 THEN GVL_DIAGNOSTICS_EXT.G_Health_Safety := 1.0; END_IF;

IF GVL_DIAGNOSTICS_EXT.G_Health_IO < 0.0 THEN GVL_DIAGNOSTICS_EXT.G_Health_IO := 0.0; END_IF;
IF GVL_DIAGNOSTICS_EXT.G_Health_IO > 1.0 THEN GVL_DIAGNOSTICS_EXT.G_Health_IO := 1.0; END_IF;

END_PROGRAM
// >>> BULK_SYNC_ANCHOR: PRG_System_Diagnostics_Ext <<<
