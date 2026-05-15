FUNCTION_BLOCK FB_Forensic_Journal_Runtime
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
END_VAR
VAR
    L_Record : ST_Forensic_Journal_Record;
    L_Write_Index : UINT;
END_VAR

IF NOT VI_Enable THEN
    GVL_Forensic_Journal.G_Runtime_Valid := FALSE;
    RETURN;
END_IF;

L_Write_Index := GVL_Forensic_Journal.G_Write_Index + 1;

IF L_Write_Index > 256 THEN
    L_Write_Index := 1;
END_IF;

// Activation / rollback events.
IF GVL_Config_Activation.G_Activation_State.Activation_Allowed
   OR GVL_Config_Activation.G_Activation_State.Rollback_Active THEN

    L_Record := (Record_Valid := TRUE);

    L_Record.Event_Time_MS := VI_System_Time_MS;
    L_Record.Event_Id := GVL_Forensic_Journal.G_Last_Event_Id + 1;

    L_Record.Config_Version :=
        GVL_Config_Activation.G_Activation_State.Active_Version;

    L_Record.Topology_Version :=
        GVL_Water_Topology_Config.G_Active_Config_Version;

    IF GVL_Config_Activation.G_Activation_State.Rollback_Active THEN

        L_Record.Rollback_Event := TRUE;
        L_Record.Event_Class := 2;
        L_Record.Event_Severity := 2;
        L_Record.Event_Text := 'Topology rollback activated';

        GVL_Forensic_Journal.G_Last_Rollback_Event_Id :=
            L_Record.Event_Id;

    ELSE

        L_Record.Activation_Event := TRUE;
        L_Record.Event_Class := 1;
        L_Record.Event_Severity := 1;
        L_Record.Event_Text := 'Topology activation completed';

        GVL_Forensic_Journal.G_Last_Activation_Event_Id :=
            L_Record.Event_Id;

    END_IF;

    GVL_Forensic_Journal.G_Journal[L_Write_Index] := L_Record;
    GVL_Forensic_Journal.G_Last_Event_Id := L_Record.Event_Id;
    GVL_Forensic_Journal.G_Write_Index := L_Write_Index;

END_IF;

// Restart continuity events.
IF GVL_Runtime_Restart_Continuity.G_Continuity_State.Restore_Completed THEN

    L_Write_Index := GVL_Forensic_Journal.G_Write_Index + 1;

    IF L_Write_Index > 256 THEN
        L_Write_Index := 1;
    END_IF;

    L_Record := (Record_Valid := TRUE);

    L_Record.Event_Time_MS := VI_System_Time_MS;
    L_Record.Event_Id := GVL_Forensic_Journal.G_Last_Event_Id + 1;

    L_Record.Restart_Event := TRUE;
    L_Record.Event_Class := 3;
    L_Record.Event_Severity := 1;

    L_Record.Config_Version :=
        GVL_Runtime_Restart_Continuity.G_Continuity_State.Active_Config_Version;

    L_Record.Event_Text := 'Warm restart continuity restored';

    GVL_Forensic_Journal.G_Journal[L_Write_Index] := L_Record;

    GVL_Forensic_Journal.G_Last_Event_Id := L_Record.Event_Id;
    GVL_Forensic_Journal.G_Write_Index := L_Write_Index;

    GVL_Forensic_Journal.G_Last_Restart_Event_Id :=
        L_Record.Event_Id;

END_IF;

// Quarantine visibility.
IF GVL_Config_Activation.G_Config_Quarantine_Active THEN

    L_Write_Index := GVL_Forensic_Journal.G_Write_Index + 1;

    IF L_Write_Index > 256 THEN
        L_Write_Index := 1;
    END_IF;

    L_Record := (Record_Valid := TRUE);

    L_Record.Event_Time_MS := VI_System_Time_MS;
    L_Record.Event_Id := GVL_Forensic_Journal.G_Last_Event_Id + 1;

    L_Record.Quarantine_Event := TRUE;
    L_Record.Event_Class := 4;
    L_Record.Event_Severity := 3;

    L_Record.Config_Version :=
        GVL_Config_Activation.G_Activation_State.Staged_Version;

    L_Record.Event_Text := 'Config quarantine active';

    GVL_Forensic_Journal.G_Journal[L_Write_Index] := L_Record;

    GVL_Forensic_Journal.G_Last_Event_Id := L_Record.Event_Id;
    GVL_Forensic_Journal.G_Write_Index := L_Write_Index;

END_IF;

GVL_Forensic_Journal.G_Runtime_Valid := TRUE;
GVL_Forensic_Journal.G_Last_Update_MS := VI_System_Time_MS;
GVL_Forensic_Journal.G_Status_Code := 0;
GVL_Forensic_Journal.G_Status_Text :=
    'Persistent forensic journal active';

END_FUNCTION_BLOCK