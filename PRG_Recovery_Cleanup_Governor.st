PROGRAM PRG_Recovery_Cleanup_Governor
VAR
    L_Now_MS : UDINT;
    L_Recovery_Valid : BOOL := TRUE;
    L_Error_Code : UDINT := 0;
    L_Error_Text : STRING(160) := '';
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_Recovery_Valid := TRUE;
L_Error_Code := 0;
L_Error_Text := '';

// ======================================================
// RECOVERY CLEANUP GOVERNOR
// ======================================================
// Governs cleanup and residue validation after recovery.
//
// Recovery governance is downstream cleanup-oriented.
// It must not feed back into runtime barrier authority.
// Runtime publication authority remains upstream and
// recovery cleanup remains a post-publication residue layer.
// ======================================================

GVL_RECOVERY_GOVERNANCE.Recovery_Semantic_Residue_Detected := FALSE;
GVL_RECOVERY_GOVERNANCE.Recovery_Degraded_State_Residual := FALSE;
GVL_RECOVERY_GOVERNANCE.Recovery_Retained_State_Residual := FALSE;
GVL_RECOVERY_GOVERNANCE.Recovery_Forced_Safe_Mode := FALSE;

// ------------------------------------------------------
// Monotonic authority linkage.
// ------------------------------------------------------

IF NOT GVL_TIME_MONOTONIC.Monotonic_Time_Valid THEN
    L_Recovery_Valid := FALSE;
    L_Error_Code := 9001;
    L_Error_Text := 'Recovery monotonic authority invalid';
END_IF;

// ------------------------------------------------------
// Recovery-active quarantine.
// ------------------------------------------------------

IF GVL_SAFETY_RECOVERY.G_Recovery_Active THEN
    GVL_RECOVERY_GOVERNANCE.Recovery_Quarantine_Active := TRUE;
    GVL_RECOVERY_GOVERNANCE.Recovery_Last_Cleanup_Start_MS := L_Now_MS;

    L_Recovery_Valid := FALSE;

    IF L_Error_Code = 0 THEN
        L_Error_Code := 9002;
        L_Error_Text := 'Recovery quarantine active';
    END_IF;
END_IF;

// ------------------------------------------------------
// Residual degraded-state detection.
// ------------------------------------------------------

IF L_Recovery_Valid AND GVL_DEGRADED.G_System_Degraded THEN
    L_Recovery_Valid := FALSE;
    L_Error_Code := 9003;
    L_Error_Text := 'Residual degraded state detected';

    GVL_RECOVERY_GOVERNANCE.Recovery_Degraded_State_Residual := TRUE;
END_IF;

// ------------------------------------------------------
// Retained-state residue detection.
// ------------------------------------------------------

IF L_Recovery_Valid AND GVL_TIME_MONOTONIC.Retained_Time_Invalid THEN
    L_Recovery_Valid := FALSE;
    L_Error_Code := 9004;
    L_Error_Text := 'Retained state residue detected';

    GVL_RECOVERY_GOVERNANCE.Recovery_Retained_State_Residual := TRUE;
END_IF;

// ------------------------------------------------------
// Publish authoritative recovery governance state.
// ------------------------------------------------------

IF L_Recovery_Valid THEN
    GVL_RECOVERY_GOVERNANCE.Recovery_Epoch := GVL_RECOVERY_GOVERNANCE.Recovery_Epoch + 1;
    GVL_RECOVERY_GOVERNANCE.Recovery_Cleanup_Epoch := GVL_RECOVERY_GOVERNANCE.Recovery_Cleanup_Epoch + 1;

    GVL_RECOVERY_GOVERNANCE.Recovery_Governance_Valid := TRUE;
    GVL_RECOVERY_GOVERNANCE.Recovery_Cleanup_Completed := TRUE;
    GVL_RECOVERY_GOVERNANCE.Recovery_Cleanup_Verified := TRUE;

    GVL_RECOVERY_GOVERNANCE.Recovery_Quarantine_Active := FALSE;
    GVL_RECOVERY_GOVERNANCE.Recovery_Last_Cleanup_End_MS := L_Now_MS;

    GVL_RECOVERY_GOVERNANCE.Recovery_Last_Error_Code := 0;
    GVL_RECOVERY_GOVERNANCE.Recovery_Last_Error_Text := '';
ELSE
    GVL_RECOVERY_GOVERNANCE.Recovery_Governance_Valid := FALSE;
    GVL_RECOVERY_GOVERNANCE.Recovery_Cleanup_Completed := FALSE;
    GVL_RECOVERY_GOVERNANCE.Recovery_Cleanup_Verified := FALSE;

    GVL_RECOVERY_GOVERNANCE.Recovery_Semantic_Residue_Detected := TRUE;
    GVL_RECOVERY_GOVERNANCE.Recovery_Forced_Safe_Mode := TRUE;

    GVL_RECOVERY_GOVERNANCE.Recovery_Last_Error_Code := L_Error_Code;
    GVL_RECOVERY_GOVERNANCE.Recovery_Last_Error_Text := L_Error_Text;

    GVL_RECOVERY_GOVERNANCE.Recovery_Invalidation_Count := GVL_RECOVERY_GOVERNANCE.Recovery_Invalidation_Count + 1;
END_IF;
END_PROGRAM
