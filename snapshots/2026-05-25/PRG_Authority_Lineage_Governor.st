PROGRAM PRG_Authority_Lineage_Governor
VAR
    L_Now_MS : UDINT;
    L_Lineage_Valid : BOOL := TRUE;
    L_Error_Code : UDINT := 0;
    L_Error_Text : STRING(160) := '';
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_Lineage_Valid := TRUE;
L_Error_Code := 0;
L_Error_Text := '';

GVL_AUTHORITY_LINEAGE.Authority_Lineage_Valid := FALSE;
GVL_AUTHORITY_LINEAGE.Warm_Restart_Continuity_Valid := FALSE;
GVL_AUTHORITY_LINEAGE.HA_Resume_Continuity_Valid := FALSE;
GVL_AUTHORITY_LINEAGE.Retained_State_Integrity_Valid := FALSE;

IF GVL_AUTHORITY_LINEAGE.Authority_Replay_Suspected THEN
    L_Lineage_Valid := FALSE;
    L_Error_Code := 25000;
    L_Error_Text := 'Authority replay suspected';
END_IF;

IF L_Lineage_Valid AND GVL_AUTHORITY_LINEAGE.Retained_State_Skew_Detected THEN
    L_Lineage_Valid := FALSE;
    L_Error_Code := 25001;
    L_Error_Text := 'Retained state skew detected';
END_IF;

IF L_Lineage_Valid AND GVL_AUTHORITY_LINEAGE.Partial_Authority_Resurrection_Detected THEN
    L_Lineage_Valid := FALSE;
    L_Error_Code := 25002;
    L_Error_Text := 'Partial authority resurrection detected';
END_IF;

IF L_Lineage_Valid AND GVL_AUTHORITY_LINEAGE.Epoch_Lineage_Discontinuity_Detected THEN
    L_Lineage_Valid := FALSE;
    L_Error_Code := 25003;
    L_Error_Text := 'Epoch lineage discontinuity detected';
END_IF;

IF L_Lineage_Valid
AND (ULINT_TO_UDINT(GVL_PHYSICAL_AUTHORITY_EPOCH.Physical_Authority_Epoch) < GVL_AUTHORITY_LINEAGE.Last_Physical_Authority_Epoch) THEN
    GVL_AUTHORITY_LINEAGE.Authority_Replay_Suspected := TRUE;
    L_Lineage_Valid := FALSE;
    L_Error_Code := 25010;
    L_Error_Text := 'Physical authority epoch rollback detected';
END_IF;

IF L_Lineage_Valid
AND (ULINT_TO_UDINT(GVL_RUNTIME_EPOCH.Runtime_Epoch) < GVL_AUTHORITY_LINEAGE.Last_Runtime_Epoch) THEN
    GVL_AUTHORITY_LINEAGE.Retained_State_Skew_Detected := TRUE;
    L_Lineage_Valid := FALSE;
    L_Error_Code := 25011;
    L_Error_Text := 'Runtime epoch rollback detected';
END_IF;

IF L_Lineage_Valid
AND (ULINT_TO_UDINT(GVL_OUTPUT_EPOCH.Output_Publication_Epoch) < GVL_AUTHORITY_LINEAGE.Last_Output_Publication_Epoch) THEN
    GVL_AUTHORITY_LINEAGE.Partial_Authority_Resurrection_Detected := TRUE;
    L_Lineage_Valid := FALSE;
    L_Error_Code := 25012;
    L_Error_Text := 'Output publication epoch rollback detected';
END_IF;

IF L_Lineage_Valid THEN
    GVL_AUTHORITY_LINEAGE.Authority_Lineage_Valid := TRUE;
    GVL_AUTHORITY_LINEAGE.Warm_Restart_Continuity_Valid := TRUE;
    GVL_AUTHORITY_LINEAGE.HA_Resume_Continuity_Valid := TRUE;
    GVL_AUTHORITY_LINEAGE.Retained_State_Integrity_Valid := TRUE;

    GVL_AUTHORITY_LINEAGE.Authority_Lineage_Epoch := ULINT_TO_UDINT(GVL_PHYSICAL_AUTHORITY_EPOCH.Physical_Authority_Epoch);
    GVL_AUTHORITY_LINEAGE.Last_Physical_Authority_Epoch := ULINT_TO_UDINT(GVL_PHYSICAL_AUTHORITY_EPOCH.Physical_Authority_Epoch);
    GVL_AUTHORITY_LINEAGE.Last_Runtime_Epoch := ULINT_TO_UDINT(GVL_RUNTIME_EPOCH.Runtime_Epoch);
    GVL_AUTHORITY_LINEAGE.Last_Output_Publication_Epoch := ULINT_TO_UDINT(GVL_OUTPUT_EPOCH.Output_Publication_Epoch);
    GVL_AUTHORITY_LINEAGE.Authority_Lineage_Last_Update_MS := L_Now_MS;
    GVL_AUTHORITY_LINEAGE.Authority_Lineage_Last_Error_Code := 0;
    GVL_AUTHORITY_LINEAGE.Authority_Lineage_Last_Error_Text := '';
ELSE
    GVL_AUTHORITY_LINEAGE.Authority_Lineage_Valid := FALSE;
    GVL_AUTHORITY_LINEAGE.Authority_Lineage_Last_Error_Code := L_Error_Code;
    GVL_AUTHORITY_LINEAGE.Authority_Lineage_Last_Error_Text := L_Error_Text;
    GVL_AUTHORITY_LINEAGE.Authority_Lineage_Invalidation_Count := GVL_AUTHORITY_LINEAGE.Authority_Lineage_Invalidation_Count + 1;
END_IF;

END_PROGRAM