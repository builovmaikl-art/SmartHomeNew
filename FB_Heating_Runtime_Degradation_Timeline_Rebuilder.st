// ==============================================================================
// Heating runtime degradation timeline rebuilder
// Read-only runtime degradation reconstruction layer.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Runtime_Degradation_Timeline_Rebuilder
VAR_INPUT
    VI_Enable : BOOL;
    VI_Event : ST_Heating_Runtime_Blackbox_Event;
END_VAR
VAR_IN_OUT
    VIO_Timeline : ST_Heating_Runtime_Blackbox_Timeline;
END_VAR
VAR
    L_Index : UINT;
END_VAR

IF NOT VI_Enable THEN
    RETURN;
END_IF;

L_Index := VIO_Timeline.Write_Index + 1;

IF L_Index > 256 THEN
    L_Index := 1;
    VIO_Timeline.Timeline_Overflow := TRUE;
END_IF;

VIO_Timeline.Events[L_Index] := VI_Event;
VIO_Timeline.Write_Index := L_Index;

IF VIO_Timeline.Event_Count < 256 THEN
    VIO_Timeline.Event_Count :=
        VIO_Timeline.Event_Count + 1;
END_IF;

VIO_Timeline.Reconstruction_Active := TRUE;
VIO_Timeline.Replay_Active := VI_Event.Event_Active;

VIO_Timeline.Root_Cause_Reconstructed :=
    VI_Event.Root_Cause_Candidate;

VIO_Timeline.Sequencing_Valid :=
    NOT VI_Event.Sequencing_Invalid;

VIO_Timeline.Ownership_Valid :=
    NOT VI_Event.Ownership_Invalid;

VIO_Timeline.Synchronization_Valid :=
    NOT VI_Event.Synchronization_Invalid;

IF VI_Event.Root_Cause_Candidate THEN
    VIO_Timeline.Status_Code := 900;
    VIO_Timeline.Status_Text := 'Heating runtime degradation reconstructed';
ELSE
    VIO_Timeline.Status_Code := 1;
    VIO_Timeline.Status_Text := 'Heating runtime forensic timeline nominal';
END_IF;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_Degradation_Timeline_Rebuilder <<<
