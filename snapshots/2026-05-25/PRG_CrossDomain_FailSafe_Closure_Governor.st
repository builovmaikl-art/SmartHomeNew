PROGRAM PRG_CrossDomain_FailSafe_Closure_Governor
VAR
    L_Now_MS : UDINT;
    L_Valid : BOOL := TRUE;
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;

GVL_CROSSDOMAIN_FAILSAFE_CLOSURE_FABRIC.CrossDomain_FailSafe_Closure_Valid := FALSE;
GVL_CROSSDOMAIN_FAILSAFE_CLOSURE_FABRIC.CrossDomain_FailSafe_Closure_Granted := FALSE;
GVL_CROSSDOMAIN_FAILSAFE_CLOSURE_FABRIC.CrossDomain_FailSafe_Closure_Quarantine_Active := TRUE;

IF NOT GVL_PHYSICAL_SAFESTATE_LATTICE_FABRIC.Physical_SafeState_Lattice_Granted THEN
    L_Valid := FALSE;
END_IF;

IF GVL_CROSSDOMAIN_FAILSAFE_CLOSURE_FABRIC.CrossDomain_FailSafe_Conflict_Detected
OR GVL_CROSSDOMAIN_FAILSAFE_CLOSURE_FABRIC.Unsafe_Recovery_Topology_Detected
OR GVL_CROSSDOMAIN_FAILSAFE_CLOSURE_FABRIC.CrossDomain_Recovery_Race_Detected
OR GVL_CROSSDOMAIN_FAILSAFE_CLOSURE_FABRIC.Distributed_SafeState_Fork_Detected
OR GVL_CROSSDOMAIN_FAILSAFE_CLOSURE_FABRIC.PowerDomain_Unsafe_Reactivation_Detected
OR GVL_CROSSDOMAIN_FAILSAFE_CLOSURE_FABRIC.MultiDomain_Recovery_Deadlock_Detected THEN
    L_Valid := FALSE;
END_IF;

IF L_Valid THEN
    GVL_CROSSDOMAIN_FAILSAFE_CLOSURE_FABRIC.CrossDomain_FailSafe_Closure_Valid := TRUE;
    GVL_CROSSDOMAIN_FAILSAFE_CLOSURE_FABRIC.CrossDomain_FailSafe_Closure_Granted := TRUE;
    GVL_CROSSDOMAIN_FAILSAFE_CLOSURE_FABRIC.CrossDomain_FailSafe_Closure_Quarantine_Active := FALSE;

    GVL_CROSSDOMAIN_FAILSAFE_CLOSURE_FABRIC.CrossDomain_SafeState_Compatibility_Valid := TRUE;
    GVL_CROSSDOMAIN_FAILSAFE_CLOSURE_FABRIC.FailSafe_Topology_Closure_Canonical := TRUE;
    GVL_CROSSDOMAIN_FAILSAFE_CLOSURE_FABRIC.MultiDomain_SafeTransition_Stable := TRUE;
    GVL_CROSSDOMAIN_FAILSAFE_CLOSURE_FABRIC.SafeState_Recovery_Ordering_Bounded := TRUE;
    GVL_CROSSDOMAIN_FAILSAFE_CLOSURE_FABRIC.Physical_Domain_Isolation_Coherent := TRUE;

    GVL_CROSSDOMAIN_FAILSAFE_CLOSURE_FABRIC.CrossDomain_FailSafe_Closure_Epoch :=
        GVL_PHYSICAL_SAFESTATE_LATTICE_FABRIC.Physical_SafeState_Lattice_Epoch;

    GVL_CROSSDOMAIN_FAILSAFE_CLOSURE_FABRIC.CrossDomain_FailSafe_Closure_Epoch_Coherent := TRUE;
    GVL_CROSSDOMAIN_FAILSAFE_CLOSURE_FABRIC.CrossDomain_FailSafe_Closure_Last_Update_MS := L_Now_MS;
    GVL_CROSSDOMAIN_FAILSAFE_CLOSURE_FABRIC.CrossDomain_FailSafe_Closure_Lease_Expired := FALSE;
END_IF;

END_PROGRAM