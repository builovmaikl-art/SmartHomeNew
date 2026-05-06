// ==============================================================================
// Heating runtime fault replay analyzer
// Read-only runtime forensic replay layer.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Runtime_Fault_Replay_Analyzer
VAR_INPUT
    VI_Enable : BOOL;
    VI_Event : ST_Heating_Runtime_Blackbox_Event;
END_VAR
VAR_OUTPUT
    VO_Replay_Active : BOOL;
    VO_Root_Cause_Reconstructed : BOOL;

    VO_Status_Code : UINT;
    VO_Status_Text : STRING(128);
END_VAR

VO_Replay_Active := FALSE;
VO_Root_Cause_Reconstructed := FALSE;

VO_Status_Code := 0;
VO_Status_Text := 'Heating runtime replay analyzer disabled';

IF NOT VI_Enable THEN
    RETURN;
END_IF;

VO_Replay_Active := VI_Event.Event_Active;

VO_Root_Cause_Reconstructed :=
    VI_Event.Root_Cause_Candidate OR
    VI_Event.Critical_Path OR
    VI_Event.Sequencing_Invalid OR
    VI_Event.Ownership_Invalid OR
    VI_Event.Synchronization_Invalid;

IF VO_Root_Cause_Reconstructed THEN
    VO_Status_Code := 900;
    VO_Status_Text := 'Heating runtime fault replay reconstructed';
ELSE
    VO_Status_Code := 1;
    VO_Status_Text := 'Heating runtime replay nominal';
END_IF;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_Fault_Replay_Analyzer <<<
