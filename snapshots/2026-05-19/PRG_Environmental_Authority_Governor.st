PROGRAM PRG_Environmental_Authority_Governor
VAR
    L_Now_MS : UDINT;
    L_Environment_Valid : BOOL := TRUE;
    L_Error_Code : UDINT := 0;
    L_Error_Text : STRING(160) := '';
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_Environment_Valid := TRUE;
L_Error_Code := 0;
L_Error_Text := '';

// Fail-safe defaults.
GVL_ENVIRONMENTAL_AUTHORITY.Environmental_Authority_Valid := FALSE;
GVL_ENVIRONMENTAL_AUTHORITY.Environmental_Authority_Granted := FALSE;
GVL_ENVIRONMENTAL_AUTHORITY.Environmental_Quarantine_Active := TRUE;

GVL_ENVIRONMENTAL_AUTHORITY.External_Environment_Causally_Compatible := FALSE;
GVL_ENVIRONMENTAL_AUTHORITY.Utility_Environment_Stable := FALSE;
GVL_ENVIRONMENTAL_AUTHORITY.Hydraulic_Source_Stable := FALSE;
GVL_ENVIRONMENTAL_AUTHORITY.Thermal_Environment_Stable := FALSE;
GVL_ENVIRONMENTAL_AUTHORITY.Airflow_Environment_Stable := FALSE;

// Environmental authority requires temporal stability.
IF NOT GVL_TEMPORAL_STABILITY.Temporal_Stability_Granted THEN
    L_Environment_Valid := FALSE;
    L_Error_Code := 29000;
    L_Error_Text := 'Temporal stability authority not granted';
END_IF;

// Freeze propagation detection.
IF GVL_ENVIRONMENTAL_AUTHORITY.Freeze_Front_Propagation_Detected THEN
    L_Environment_Valid := FALSE;
    L_Error_Code := 29001;
    L_Error_Text := 'Freeze-front propagation detected';
END_IF;

// Utility instability propagation.
IF GVL_ENVIRONMENTAL_AUTHORITY.Utility_Instability_Propagation_Detected THEN
    L_Environment_Valid := FALSE;
    L_Error_Code := 29002;
    L_Error_Text := 'Utility instability propagation detected';
END_IF;

// Hydraulic collapse prediction.
IF GVL_ENVIRONMENTAL_AUTHORITY.External_Hydraulic_Collapse_Detected THEN
    L_Environment_Valid := FALSE;
    L_Error_Code := 29003;
    L_Error_Text := 'External hydraulic collapse detected';
END_IF;

// Airflow icing conditions.
IF GVL_ENVIRONMENTAL_AUTHORITY.Airflow_Icing_Condition_Detected THEN
    L_Environment_Valid := FALSE;
    L_Error_Code := 29004;
    L_Error_Text := 'Airflow icing condition detected';
END_IF;

// Environmental rebound race.
IF GVL_ENVIRONMENTAL_AUTHORITY.Environmental_Rebound_Race_Detected THEN
    L_Environment_Valid := FALSE;
    L_Error_Code := 29005;
    L_Error_Text := 'Environmental rebound race detected';
END_IF;

// External environment validation.
IF L_Environment_Valid
AND NOT GVL_ENVIRONMENTAL_AUTHORITY.Mains_Quality_Valid THEN
    L_Environment_Valid := FALSE;
    L_Error_Code := 29010;
    L_Error_Text := 'Mains quality invalid';
END_IF;

IF L_Environment_Valid
AND NOT GVL_ENVIRONMENTAL_AUTHORITY.Supply_Water_Available THEN
    L_Environment_Valid := FALSE;
    L_Error_Code := 29011;
    L_Error_Text := 'Supply water unavailable';
END_IF;

IF L_Environment_Valid
AND NOT GVL_ENVIRONMENTAL_AUTHORITY.Outdoor_Airflow_Valid THEN
    L_Environment_Valid := FALSE;
    L_Error_Code := 29012;
    L_Error_Text := 'Outdoor airflow invalid';
END_IF;

IF L_Environment_Valid
AND NOT GVL_ENVIRONMENTAL_AUTHORITY.Freeze_Protection_Valid THEN
    L_Environment_Valid := FALSE;
    L_Error_Code := 29013;
    L_Error_Text := 'Freeze protection invalid';
END_IF;

IF L_Environment_Valid THEN
    GVL_ENVIRONMENTAL_AUTHORITY.Environmental_Authority_Valid := TRUE;
    GVL_ENVIRONMENTAL_AUTHORITY.Environmental_Authority_Granted := TRUE;
    GVL_ENVIRONMENTAL_AUTHORITY.Environmental_Quarantine_Active := FALSE;

    GVL_ENVIRONMENTAL_AUTHORITY.External_Environment_Causally_Compatible := TRUE;
    GVL_ENVIRONMENTAL_AUTHORITY.Utility_Environment_Stable := TRUE;
    GVL_ENVIRONMENTAL_AUTHORITY.Hydraulic_Source_Stable := TRUE;
    GVL_ENVIRONMENTAL_AUTHORITY.Thermal_Environment_Stable := TRUE;
    GVL_ENVIRONMENTAL_AUTHORITY.Airflow_Environment_Stable := TRUE;

    GVL_ENVIRONMENTAL_AUTHORITY.Environmental_Authority_Epoch :=
        GVL_TEMPORAL_STABILITY.Temporal_Stability_Epoch;

    GVL_ENVIRONMENTAL_AUTHORITY.Environmental_Authority_Epoch_Coherent := TRUE;

    GVL_ENVIRONMENTAL_AUTHORITY.Environmental_Last_Update_MS :=
        L_Now_MS;

    GVL_ENVIRONMENTAL_AUTHORITY.Environmental_Lease_Expired := FALSE;

    GVL_ENVIRONMENTAL_AUTHORITY.Environmental_Last_Error_Code := 0;
    GVL_ENVIRONMENTAL_AUTHORITY.Environmental_Last_Error_Text := '';
ELSE
    GVL_ENVIRONMENTAL_AUTHORITY.Environmental_Authority_Valid := FALSE;
    GVL_ENVIRONMENTAL_AUTHORITY.Environmental_Authority_Granted := FALSE;
    GVL_ENVIRONMENTAL_AUTHORITY.Environmental_Quarantine_Active := TRUE;

    GVL_ENVIRONMENTAL_AUTHORITY.Environmental_Lease_Expired := TRUE;

    GVL_ENVIRONMENTAL_AUTHORITY.Environmental_Last_Error_Code :=
        L_Error_Code;

    GVL_ENVIRONMENTAL_AUTHORITY.Environmental_Last_Error_Text :=
        L_Error_Text;

    GVL_ENVIRONMENTAL_AUTHORITY.Environmental_Invalidation_Count :=
        GVL_ENVIRONMENTAL_AUTHORITY.Environmental_Invalidation_Count + 1;
END_IF;

END_PROGRAM