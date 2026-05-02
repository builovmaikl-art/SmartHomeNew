PROGRAM PRG_System_Diagnostics_Ext
VAR
    L_Error_Heating : BOOL;
    L_Error_Safety : BOOL;
    L_Error_IO : BOOL;
END_VAR

// --- Detect errors ---
L_Error_Heating := GVL_STATE.G_Heating_Subsystem_Degraded;
L_Error_Safety := GVL_STATE.G_Safety_Gas_Alarm OR GVL_STATE.G_Safety_Leak_Alarm OR GVL_STATE.G_Safety_Smoke_Alarm;
L_Error_IO := GVL_STATE.G_Heating_IO_Fault;

// --- Heating ---
IF L_Error_Heating THEN
    GVL_DIAGNOSTICS_EXT.G_Error_Count_Heating := GVL_DIAGNOSTICS_EXT.G_Error_Count_Heating + 1;
    GVL_DIAGNOSTICS_EXT.G_Last_Error_Time_Heating := GVL_TIME_SERVICE.G_Now_MS;
    GVL_DIAGNOSTICS_EXT.G_Health_Heating := GVL_DIAGNOSTICS_EXT.G_Health_Heating - 0.05;
ELSE
    GVL_DIAGNOSTICS_EXT.G_Health_Heating := GVL_DIAGNOSTICS_EXT.G_Health_Heating + 0.01;
END_IF;

// Clamp
IF GVL_DIAGNOSTICS_EXT.G_Health_Heating < 0.0 THEN
    GVL_DIAGNOSTICS_EXT.G_Health_Heating := 0.0;
ELSIF GVL_DIAGNOSTICS_EXT.G_Health_Heating > 1.0 THEN
    GVL_DIAGNOSTICS_EXT.G_Health_Heating := 1.0;
END_IF;

// --- Safety ---
IF L_Error_Safety THEN
    GVL_DIAGNOSTICS_EXT.G_Error_Count_Safety := GVL_DIAGNOSTICS_EXT.G_Error_Count_Safety + 1;
    GVL_DIAGNOSTICS_EXT.G_Last_Error_Time_Safety := GVL_TIME_SERVICE.G_Now_MS;
    GVL_DIAGNOSTICS_EXT.G_Health_Safety := GVL_DIAGNOSTICS_EXT.G_Health_Safety - 0.1;
ELSE
    GVL_DIAGNOSTICS_EXT.G_Health_Safety := GVL_DIAGNOSTICS_EXT.G_Health_Safety + 0.02;
END_IF;

IF GVL_DIAGNOSTICS_EXT.G_Health_Safety < 0.0 THEN
    GVL_DIAGNOSTICS_EXT.G_Health_Safety := 0.0;
ELSIF GVL_DIAGNOSTICS_EXT.G_Health_Safety > 1.0 THEN
    GVL_DIAGNOSTICS_EXT.G_Health_Safety := 1.0;
END_IF;

// --- IO ---
IF L_Error_IO THEN
    GVL_DIAGNOSTICS_EXT.G_Error_Count_IO := GVL_DIAGNOSTICS_EXT.G_Error_Count_IO + 1;
    GVL_DIAGNOSTICS_EXT.G_Last_Error_Time_IO := GVL_TIME_SERVICE.G_Now_MS;
    GVL_DIAGNOSTICS_EXT.G_Health_IO := GVL_DIAGNOSTICS_EXT.G_Health_IO - 0.05;
ELSE
    GVL_DIAGNOSTICS_EXT.G_Health_IO := GVL_DIAGNOSTICS_EXT.G_Health_IO + 0.01;
END_IF;

IF GVL_DIAGNOSTICS_EXT.G_Health_IO < 0.0 THEN
    GVL_DIAGNOSTICS_EXT.G_Health_IO := 0.0;
ELSIF GVL_DIAGNOSTICS_EXT.G_Health_IO > 1.0 THEN
    GVL_DIAGNOSTICS_EXT.G_Health_IO := 1.0;
END_IF;

END_PROGRAM
