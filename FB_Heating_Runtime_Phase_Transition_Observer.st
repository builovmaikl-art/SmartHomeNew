// ==============================================================================
// Heating runtime phase transition observer
// Read-only phase-aware runtime observation layer.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Runtime_Phase_Transition_Observer
VAR_INPUT
    VI_Enable : BOOL;
    VI_Current_Phase : E_Heating_Runtime_Phase;
    VI_System_Time_MS : UDINT;
END_VAR
VAR_OUTPUT
    VO_Transition : ST_Heating_Runtime_Phase_Transition;
END_VAR
VAR
    L_Previous_Phase : E_Heating_Runtime_Phase;
    L_Transition_Start_MS : UDINT;
END_VAR

VO_Transition.Transition_Active := FALSE;
VO_Transition.Transition_Completed := FALSE;
VO_Transition.Transition_Failed := FALSE;
VO_Transition.Status_Code := 0;
VO_Transition.Status_Text := 'Phase transition observer disabled';

IF NOT VI_Enable THEN
    RETURN;
END_IF;

IF VI_Current_Phase <> L_Previous_Phase THEN

    VO_Transition.Previous_Phase := L_Previous_Phase;
    VO_Transition.Current_Phase := VI_Current_Phase;
    VO_Transition.Next_Phase := VI_Current_Phase;

    VO_Transition.Transition_Active := TRUE;
    VO_Transition.Transition_Completed := TRUE;
    VO_Transition.Transition_Failed := FALSE;

    L_Transition_Start_MS := VI_System_Time_MS;

    VO_Transition.Transition_Start_MS := L_Transition_Start_MS;
    VO_Transition.Transition_End_MS := VI_System_Time_MS;
    VO_Transition.Transition_Duration_MS :=
        VI_System_Time_MS - L_Transition_Start_MS;

    VO_Transition.Sequencing_Valid := TRUE;
    VO_Transition.Ownership_Valid := TRUE;
    VO_Transition.Synchronization_Valid := TRUE;

    VO_Transition.Status_Code := 1;
    VO_Transition.Status_Text := 'Heating runtime phase transition observed';

    L_Previous_Phase := VI_Current_Phase;
END_IF;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_Phase_Transition_Observer <<<
