// ==============================================================================
// Heating runtime orchestration shell
// Prepared integration boundary for future controlled extraction.
// DOES NOT own heating logic.
// DOES NOT own diagnostics.
// DOES NOT own OpenTherm transport.
// DOES NOT own safety.
// NOT connected to live runtime yet.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Runtime_Orchestration_Shell
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
END_VAR
VAR_OUTPUT
    VO_Runtime_Context : ST_Heating_Runtime_Context;
    VO_Runtime_Event_Buffer : ST_Heating_Runtime_Event_Buffer;

    VO_Contract_Valid : BOOL;
    VO_Runtime_Ready : BOOL;
    VO_Runtime_Fault : BOOL;
    VO_Status_Code : UINT;
    VO_Status_Text : STRING(128);
END_VAR
VAR
    fbCoordinator : FB_Heating_Runtime_Coordinator;
    fbValidator : FB_Heating_Runtime_Contract_Validator;
    fbEventManager : FB_Heating_Runtime_Event_Manager;

    L_Event : ST_Heating_Runtime_Phase_Event;
    L_Event_Stored : BOOL;
    L_Buffer_Overflow : BOOL;
    L_Event_Manager_Ready : BOOL;
    L_Event_Manager_Code : UINT;
    L_Event_Manager_Text : STRING(128);
END_VAR

// ======================================================
// DEFAULTS
// ======================================================
VO_Contract_Valid := FALSE;
VO_Runtime_Ready := FALSE;
VO_Runtime_Fault := FALSE;
VO_Status_Code := 0;
VO_Status_Text := 'Heating runtime orchestration shell disabled';

IF NOT VI_Enable THEN
    RETURN;
END_IF;

// ======================================================
// COORDINATION CONTEXT
// ======================================================
fbCoordinator(
    VI_Enable := VI_Enable,
    VO_Runtime_Context => VO_Runtime_Context
);

// ======================================================
// CONTRACT VALIDATION
// ======================================================
fbValidator(
    VI_Context := VO_Runtime_Context,
    VO_Contract_Valid => VO_Contract_Valid
);

// ======================================================
// PHASE EVENT PROJECTION
// ======================================================
L_Event.Phase := VO_Runtime_Context.Current_Phase;
L_Event.Event_Active := VI_Enable;
L_Event.Event_Completed := VO_Runtime_Context.Runtime_Ready;
L_Event.Event_Failed := VO_Runtime_Context.Runtime_Fault OR NOT VO_Contract_Valid;
L_Event.Start_Time_MS := VI_System_Time_MS;
L_Event.End_Time_MS := VI_System_Time_MS;
L_Event.Duration_MS := 0;
L_Event.Ordering_Valid := VO_Runtime_Context.DHW_Before_Heating_Valid AND VO_Runtime_Context.State_Publication_Before_Diagnostics_Valid AND VO_Runtime_Context.Output_Projection_Last_Valid;
L_Event.Isolation_Valid := VO_Runtime_Context.Diagnostics_Isolation_Valid AND VO_Runtime_Context.Explainability_Isolation_Valid AND VO_Runtime_Context.Safety_Isolation_Valid AND VO_Runtime_Context.OpenTherm_Ownership_Valid AND VO_Runtime_Context.Cascade_Ownership_Valid;
L_Event.Status_Code := VO_Runtime_Context.Runtime_Status_Code;
L_Event.Status_Text := VO_Runtime_Context.Runtime_Status_Text;
L_Event.Diagnostics_Visible := VO_Runtime_Context.Diagnostics_Isolation_Valid;
L_Event.Explainability_Visible := VO_Runtime_Context.Explainability_Isolation_Valid;
L_Event.Safety_Integrity_Valid := VO_Runtime_Context.Safety_Isolation_Valid;
L_Event.OpenTherm_Ownership_Valid := VO_Runtime_Context.OpenTherm_Ownership_Valid;
L_Event.Cascade_Ownership_Valid := VO_Runtime_Context.Cascade_Ownership_Valid;

fbEventManager(
    VI_Enable := VI_Enable,
    VI_Event := L_Event,
    VIO_Buffer := VO_Runtime_Event_Buffer,
    VO_Event_Stored => L_Event_Stored,
    VO_Buffer_Overflow => L_Buffer_Overflow,
    VO_Manager_Ready => L_Event_Manager_Ready,
    VO_Manager_Status_Code => L_Event_Manager_Code,
    VO_Manager_Status_Text => L_Event_Manager_Text
);

// ======================================================
// SHELL STATUS
// ======================================================
VO_Runtime_Ready := VO_Runtime_Context.Runtime_Ready AND VO_Contract_Valid AND L_Event_Manager_Ready;
VO_Runtime_Fault := VO_Runtime_Context.Runtime_Fault OR NOT VO_Contract_Valid OR L_Buffer_Overflow;

IF VO_Runtime_Fault THEN
    VO_Status_Code := 900;
    VO_Status_Text := 'Heating runtime orchestration shell fault';
ELSIF VO_Runtime_Ready THEN
    VO_Status_Code := 100;
    VO_Status_Text := 'Heating runtime orchestration shell ready';
ELSE
    VO_Status_Code := 10;
    VO_Status_Text := 'Heating runtime orchestration shell active';
END_IF;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_Orchestration_Shell <<<
