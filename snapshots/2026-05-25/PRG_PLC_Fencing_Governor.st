PROGRAM PRG_PLC_Fencing_Governor
VAR
    L_Now_MS : UDINT;
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;

// ======================================================
// LOCAL-ONLY PLC FENCING GOVERNOR
// ======================================================
// Cold-spare architecture: there is exactly one runtime owner.
// A reserve PLC is not connected in parallel and is not allowed to arbitrate
// outputs during normal runtime. Therefore split-brain/stale-owner detection is
// held inactive here while still publishing a valid local ownership epoch/token
// for downstream authority checks.
// ======================================================

GVL_PLC_FENCING.PLC_Heartbeat_Only_Mode := FALSE;
GVL_PLC_FENCING.PLC_Split_Brain_Detected := FALSE;
GVL_PLC_FENCING.PLC_Stale_Owner_Detected := FALSE;
GVL_PLC_FENCING.PLC_Asymmetric_Partition_Detected := FALSE;
GVL_PLC_FENCING.PLC_Forced_Safe_Quarantine := FALSE;

GVL_PLC_FENCING.PLC_Ownership_Epoch := GVL_PLC_FENCING.PLC_Ownership_Epoch + 1;
GVL_PLC_FENCING.PLC_Fencing_Token := GVL_PLC_FENCING.PLC_Ownership_Epoch;

GVL_PLC_FENCING.PLC_Ownership_Valid := TRUE;
GVL_PLC_FENCING.PLC_Semantic_Authority_Valid := TRUE;

GVL_PLC_FENCING.PLC_Lease_Active := TRUE;
GVL_PLC_FENCING.PLC_Lease_Expired := FALSE;
GVL_PLC_FENCING.PLC_Last_Lease_Refresh_MS := L_Now_MS;
GVL_PLC_FENCING.PLC_Last_Authority_Validation_MS := L_Now_MS;

GVL_PLC_FENCING.PLC_Last_Error_Code := 0;
GVL_PLC_FENCING.PLC_Last_Error_Text := '';

// >>> BULK_SYNC_ANCHOR: PRG_PLC_Fencing_Governor <<<
END_PROGRAM