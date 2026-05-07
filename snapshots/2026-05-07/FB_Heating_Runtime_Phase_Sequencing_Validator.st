// ==============================================================================
// Heating runtime phase sequencing validator
// Read-only deterministic sequencing validator.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Runtime_Phase_Sequencing_Validator
VAR_INPUT
    VI_Enable : BOOL;
    VI_Transition : ST_Heating_Runtime_Phase_Transition;
END_VAR
VAR_OUTPUT
    VO_Sequencing_Valid : BOOL;
    VO_Status_Code : UINT;
    VO_Status_Text : STRING(128);
END_VAR

VO_Sequencing_Valid := FALSE;
VO_Status_Code := 0;
VO_Status_Text := 'Heating runtime sequencing validator disabled';

IF NOT VI_Enable THEN
    RETURN;
END_IF;

VO_Sequencing_Valid :=
    VI_Transition.Sequencing_Valid AND
    VI_Transition.Ownership_Valid AND
    VI_Transition.Synchronization_Valid AND
    NOT VI_Transition.Transition_Failed;

IF VO_Sequencing_Valid THEN
    VO_Status_Code := 1;
    VO_Status_Text := 'Heating runtime sequencing valid';
ELSE
    VO_Status_Code := 100;
    VO_Status_Text := 'Heating runtime sequencing invalid';
END_IF;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_Phase_Sequencing_Validator <<<
