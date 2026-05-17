PROGRAM PRG_Deterministic_Recovery_Path_Governor
VAR
    L_Now_MS : UDINT;
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;

IF GVL_CROSSDOMAIN_FAILSAFE_CLOSURE_FABRIC.CrossDomain_FailSafe_Closure_Granted
AND NOT GVL_DETERMINISTIC_RECOVERY_PATH_FABRIC.Unsafe_Recovery_Path_Detected
AND NOT GVL_DETERMINISTIC_RECOVERY_PATH_FABRIC.Recovery_Path_Divergence_Detected
AND NOT GVL_DETERMINISTIC_RECOVERY_PATH_FABRIC.Recovery_Causality_Break_Detected
AND NOT GVL_DETERMINISTIC_RECOVERY_PATH_FABRIC.Distributed_Recovery_Fork_Detected THEN

    GVL_DETERMINISTIC_RECOVERY_PATH_FABRIC.Deterministic_Recovery_Path_Valid := TRUE;
    GVL_DETERMINISTIC_RECOVERY_PATH_FABRIC.Deterministic_Recovery_Path_Granted := TRUE;
    GVL_DETERMINISTIC_RECOVERY_PATH_FABRIC.Deterministic_Recovery_Path_Canonical := TRUE;
    GVL_DETERMINISTIC_RECOVERY_PATH_FABRIC.Recovery_Lineage_Causality_Valid := TRUE;
    GVL_DETERMINISTIC_RECOVERY_PATH_FABRIC.Recovery_Physical_Convergence_Stable := TRUE;
    GVL_DETERMINISTIC_RECOVERY_PATH_FABRIC.Recovery_Timeline_Monotonic := TRUE;

    GVL_DETERMINISTIC_RECOVERY_PATH_FABRIC.Deterministic_Recovery_Path_Epoch :=
        GVL_CROSSDOMAIN_FAILSAFE_CLOSURE_FABRIC.CrossDomain_FailSafe_Closure_Epoch;

    GVL_DETERMINISTIC_RECOVERY_PATH_FABRIC.Deterministic_Recovery_Path_Last_Update_MS :=
        L_Now_MS;
END_IF;

END_PROGRAM