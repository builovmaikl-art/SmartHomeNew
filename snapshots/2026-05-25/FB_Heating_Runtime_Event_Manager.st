// ==============================================================================
// Heating runtime event manager
// Read-only orchestration telemetry/event layer.
// DOES NOT own runtime.
// DOES NOT own heating logic.
// DOES NOT own diagnostics.
// DOES NOT own OpenTherm transport.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Runtime_Event_Manager
VAR_INPUT
    VI_Enable : BOOL;
    VI_Event : ST_Heating_Runtime_Phase_Event;
END_VAR
VAR_IN_OUT
    VIO_Buffer : ST_Heating_Runtime_Event_Buffer;
END_VAR
VAR_OUTPUT
    VO_Event_Stored : BOOL;
    VO_Buffer_Overflow : BOOL;
    VO_Manager_Ready : BOOL;
    VO_Manager_Status_Code : UINT;
    VO_Manager_Status_Text : STRING(128);
END_VAR
VAR
    L_Write_Index : UINT;
END_VAR

// ======================================================
// DEFAULTS
// ======================================================
VO_Event_Stored := FALSE;
VO_Buffer_Overflow := FALSE;
VO_Manager_Ready := FALSE;
VO_Manager_Status_Code := 0;
VO_Manager_Status_Text := 'Heating runtime event manager disabled';

IF NOT VI_Enable THEN
    RETURN;
END_IF;

// ======================================================
// BUFFER VALIDATION
// ======================================================
IF VIO_Buffer.Write_Index > 32 THEN
    VIO_Buffer.Write_Index := 1;
END_IF;

IF VIO_Buffer.Read_Index > 32 THEN
    VIO_Buffer.Read_Index := 1;
END_IF;

// ======================================================
// WRITE INDEX
// ======================================================
L_Write_Index := VIO_Buffer.Write_Index + 1;

IF L_Write_Index > 32 THEN
    L_Write_Index := 1;
END_IF;

// ======================================================
// STORE EVENT
// ======================================================
VIO_Buffer.Events[L_Write_Index] := VI_Event;
VIO_Buffer.Write_Index := L_Write_Index;

IF VIO_Buffer.Event_Count < 32 THEN
    VIO_Buffer.Event_Count := VIO_Buffer.Event_Count + 1;
ELSE
    VIO_Buffer.Overflow := TRUE;
    VO_Buffer_Overflow := TRUE;
END_IF;

// ======================================================
// BUFFER INTEGRITY
// ======================================================
VIO_Buffer.Ordering_Integrity_Valid :=
    VI_Event.Ordering_Valid;

VIO_Buffer.Isolation_Integrity_Valid :=
    VI_Event.Isolation_Valid;

VIO_Buffer.Diagnostics_Visibility_Valid :=
    VI_Event.Diagnostics_Visible;

VIO_Buffer.Explainability_Visibility_Valid :=
    VI_Event.Explainability_Visible;

VIO_Buffer.OpenTherm_Ownership_Valid :=
    VI_Event.OpenTherm_Ownership_Valid;

VIO_Buffer.Cascade_Ownership_Valid :=
    VI_Event.Cascade_Ownership_Valid;

VIO_Buffer.Safety_Ownership_Valid :=
    VI_Event.Safety_Integrity_Valid;

VIO_Buffer.Lifecycle_Integrity_Valid :=
    NOT VI_Event.Event_Failed;

// ======================================================
// BUFFER STATUS
// ======================================================
IF VO_Buffer_Overflow THEN
    VIO_Buffer.Status_Code := 100;
    VIO_Buffer.Status_Text := 'Heating runtime event buffer overflow';
ELSE
    VIO_Buffer.Status_Code := 1;
    VIO_Buffer.Status_Text := 'Heating runtime event stored';
END_IF;

// ======================================================
// OUTPUT STATUS
// ======================================================
VO_Event_Stored := TRUE;
VO_Manager_Ready := TRUE;
VO_Manager_Status_Code := VIO_Buffer.Status_Code;
VO_Manager_Status_Text := VIO_Buffer.Status_Text;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_Event_Manager <<<
