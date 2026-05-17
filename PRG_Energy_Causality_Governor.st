PROGRAM PRG_Energy_Causality_Governor
VAR
    L_Now_MS : UDINT;
    L_Energy_Valid : BOOL := TRUE;
    L_Error_Code : UDINT := 0;
    L_Error_Text : STRING(160) := '';
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_Energy_Valid := TRUE;
L_Error_Code := 0;
L_Error_Text := '';

// Fail-safe defaults.
GVL_ENERGY_CAUSALITY_FABRIC.Energy_Causality_Valid := FALSE;
GVL_ENERGY_CAUSALITY_FABRIC.Energy_Causality_Granted := FALSE;
GVL_ENERGY_CAUSALITY_FABRIC.Energy_Causality_Quarantine_Active := TRUE;

GVL_ENERGY_CAUSALITY_FABRIC.Hydraulic_Energy_State_Valid := FALSE;
GVL_ENERGY_CAUSALITY_FABRIC.Thermal_Energy_State_Valid := FALSE;
GVL_ENERGY_CAUSALITY_FABRIC.Electrical_Load_State_Valid := FALSE;
GVL_ENERGY_CAUSALITY_FABRIC.Motor_Energy_Envelope_Valid := FALSE;
GVL_ENERGY_CAUSALITY_FABRIC.Distributed_Load_Coherent := FALSE;

// Actuator semantic verification required.
IF NOT GVL_ACTUATOR_SEMANTIC_VERIFICATION.Actuator_Semantic_Verification_Granted THEN
    L_Energy_Valid := FALSE;
    L_Error_Code := 37000;
    L_Error_Text := 'Actuator semantic verification not granted';
END_IF;

// Energy divergence detectors.
IF GVL_ENERGY_CAUSALITY_FABRIC.DryRun_Energy_State_Detected THEN
    L_Energy_Valid := FALSE;
    L_Error_Code := 37001;
    L_Error_Text := 'Dry-run energy state detected';
END_IF;

IF GVL_ENERGY_CAUSALITY_FABRIC.Thermal_Extraction_Divergence_Detected THEN
    L_Energy_Valid := FALSE;
    L_Error_Code := 37002;
    L_Error_Text := 'Thermal extraction divergence detected';
END_IF;

IF GVL_ENERGY_CAUSALITY_FABRIC.Load_Synchronization_Spike_Detected THEN
    L_Energy_Valid := FALSE;
    L_Error_Code := 37003;
    L_Error_Text := 'Load synchronization spike detected';
END_IF;

IF GVL_ENERGY_CAUSALITY_FABRIC.Hydraulic_Energy_Starvation_Detected THEN
    L_Energy_Valid := FALSE;
    L_Error_Code := 37004;
    L_Error_Text := 'Hydraulic energy starvation detected';
END_IF;

IF GVL_ENERGY_CAUSALITY_FABRIC.Distributed_Transient_Overload_Detected THEN
    L_Energy_Valid := FALSE;
    L_Error_Code := 37005;
    L_Error_Text := 'Distributed transient overload detected';
END_IF;

IF GVL_ENERGY_CAUSALITY_FABRIC.Energy_Recovery_Instability_Detected THEN
    L_Energy_Valid := FALSE;
    L_Error_Code := 37006;
    L_Error_Text := 'Energy recovery instability detected';
END_IF;

// Stable energy envelope validation.
IF L_Energy_Valid
AND NOT GVL_ENERGY_CAUSALITY_FABRIC.Energy_Envelope_Stable THEN
    L_Energy_Valid := FALSE;
    L_Error_Code := 37010;
    L_Error_Text := 'Energy envelope unstable';
END_IF;

IF L_Energy_Valid
AND NOT GVL_ENERGY_CAUSALITY_FABRIC.Transient_Load_Stable THEN
    L_Energy_Valid := FALSE;
    L_Error_Code := 37011;
    L_Error_Text := 'Transient load stability invalid';
END_IF;

IF L_Energy_Valid
AND NOT GVL_ENERGY_CAUSALITY_FABRIC.Thermal_Accumulation_Stable THEN
    L_Energy_Valid := FALSE;
    L_Error_Code := 37012;
    L_Error_Text := 'Thermal accumulation unstable';
END_IF;

IF L_Energy_Valid
AND NOT GVL_ENERGY_CAUSALITY_FABRIC.Recovery_Energy_Coherent THEN
    L_Energy_Valid := FALSE;
    L_Error_Code := 37013;
    L_Error_Text := 'Recovery energy coherence invalid';
END_IF;

IF L_Energy_Valid THEN
    GVL_ENERGY_CAUSALITY_FABRIC.Energy_Causality_Valid := TRUE;
    GVL_ENERGY_CAUSALITY_FABRIC.Energy_Causality_Granted := TRUE;
    GVL_ENERGY_CAUSALITY_FABRIC.Energy_Causality_Quarantine_Active := FALSE;

    GVL_ENERGY_CAUSALITY_FABRIC.Hydraulic_Energy_State_Valid := TRUE;
    GVL_ENERGY_CAUSALITY_FABRIC.Thermal_Energy_State_Valid := TRUE;
    GVL_ENERGY_CAUSALITY_FABRIC.Electrical_Load_State_Valid := TRUE;
    GVL_ENERGY_CAUSALITY_FABRIC.Motor_Energy_Envelope_Valid := TRUE;
    GVL_ENERGY_CAUSALITY_FABRIC.Distributed_Load_Coherent := TRUE;

    GVL_ENERGY_CAUSALITY_FABRIC.Energy_Causality_Epoch :=
        GVL_ACTUATOR_SEMANTIC_VERIFICATION.Actuator_Verification_Epoch;

    GVL_ENERGY_CAUSALITY_FABRIC.Energy_Causality_Epoch_Coherent := TRUE;

    GVL_ENERGY_CAUSALITY_FABRIC.Energy_Causality_Last_Update_MS :=
        L_Now_MS;

    GVL_ENERGY_CAUSALITY_FABRIC.Energy_Causality_Lease_Expired := FALSE;

    GVL_ENERGY_CAUSALITY_FABRIC.Energy_Causality_Last_Error_Code := 0;
    GVL_ENERGY_CAUSALITY_FABRIC.Energy_Causality_Last_Error_Text := '';
ELSE
    GVL_ENERGY_CAUSALITY_FABRIC.Energy_Causality_Valid := FALSE;
    GVL_ENERGY_CAUSALITY_FABRIC.Energy_Causality_Granted := FALSE;
    GVL_ENERGY_CAUSALITY_FABRIC.Energy_Causality_Quarantine_Active := TRUE;

    GVL_ENERGY_CAUSALITY_FABRIC.Energy_Causality_Lease_Expired := TRUE;

    GVL_ENERGY_CAUSALITY_FABRIC.Energy_Causality_Last_Error_Code :=
        L_Error_Code;

    GVL_ENERGY_CAUSALITY_FABRIC.Energy_Causality_Last_Error_Text :=
        L_Error_Text;

    GVL_ENERGY_CAUSALITY_FABRIC.Energy_Causality_Invalidation_Count :=
        GVL_ENERGY_CAUSALITY_FABRIC.Energy_Causality_Invalidation_Count + 1;
END_IF;

END_PROGRAM