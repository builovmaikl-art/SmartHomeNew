PROGRAM PRG_Physical_SafeState_Lattice_Governor
VAR
    L_Now_MS : UDINT;
    L_Valid : BOOL := TRUE;
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;

GVL_PHYSICAL_SAFESTATE_LATTICE_FABRIC.Physical_SafeState_Lattice_Valid := FALSE;
GVL_PHYSICAL_SAFESTATE_LATTICE_FABRIC.Physical_SafeState_Lattice_Granted := FALSE;
GVL_PHYSICAL_SAFESTATE_LATTICE_FABRIC.Physical_SafeState_Lattice_Quarantine_Active := TRUE;

IF NOT GVL_GOVERNANCE_PUBLICATION_BINDING_FABRIC.Governance_Publication_Binding_Granted THEN
    L_Valid := FALSE;
END_IF;

IF GVL_PHYSICAL_SAFESTATE_LATTICE_FABRIC.SafeState_Ambiguity_Detected
OR GVL_PHYSICAL_SAFESTATE_LATTICE_FABRIC.Partial_SafeState_Asymmetry_Detected
OR GVL_PHYSICAL_SAFESTATE_LATTICE_FABRIC.Physical_SafeState_Deadlock_Detected
OR GVL_PHYSICAL_SAFESTATE_LATTICE_FABRIC.Unsafe_SafeState_Topology_Detected
OR GVL_PHYSICAL_SAFESTATE_LATTICE_FABRIC.Residual_Unsafe_Actuation_Detected
OR GVL_PHYSICAL_SAFESTATE_LATTICE_FABRIC.SafeState_Energy_Leakage_Detected THEN
    L_Valid := FALSE;
END_IF;

IF L_Valid THEN
    GVL_PHYSICAL_SAFESTATE_LATTICE_FABRIC.Physical_SafeState_Lattice_Valid := TRUE;
    GVL_PHYSICAL_SAFESTATE_LATTICE_FABRIC.Physical_SafeState_Lattice_Granted := TRUE;
    GVL_PHYSICAL_SAFESTATE_LATTICE_FABRIC.Physical_SafeState_Lattice_Quarantine_Active := FALSE;

    GVL_PHYSICAL_SAFESTATE_LATTICE_FABRIC.Canonical_SafeState_Topology_Valid := TRUE;
    GVL_PHYSICAL_SAFESTATE_LATTICE_FABRIC.Physical_SafeState_Lattice_Coherent := TRUE;
    GVL_PHYSICAL_SAFESTATE_LATTICE_FABRIC.Deterministic_FailSafe_Convergence_Granted := TRUE;

    GVL_PHYSICAL_SAFESTATE_LATTICE_FABRIC.Physical_SafeState_Lattice_Epoch :=
        GVL_GOVERNANCE_PUBLICATION_BINDING_FABRIC.Governance_Publication_Binding_Epoch;

    GVL_PHYSICAL_SAFESTATE_LATTICE_FABRIC.Physical_SafeState_Lattice_Epoch_Coherent := TRUE;
    GVL_PHYSICAL_SAFESTATE_LATTICE_FABRIC.Physical_SafeState_Lattice_Last_Update_MS := L_Now_MS;
    GVL_PHYSICAL_SAFESTATE_LATTICE_FABRIC.Physical_SafeState_Lattice_Lease_Expired := FALSE;
END_IF;

END_PROGRAM