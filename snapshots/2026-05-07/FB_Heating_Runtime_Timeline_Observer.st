// ==============================================================================
// Heating runtime timeline observer
// Read-only deterministic execution timeline layer.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Runtime_Timeline_Observer
VAR_INPUT
    VI_Enable : BOOL;
    VI_Frame : ST_Heating_Runtime_Execution_Frame;
END_VAR
VAR_IN_OUT
    VIO_Timeline : ST_Heating_Runtime_Execution_Timeline;
END_VAR
VAR
    L_Index : UINT;
END_VAR

IF NOT VI_Enable THEN
    RETURN;
END_IF;

// ======================================================
// SAFE INDEX NORMALIZATION
// ======================================================
IF (VIO_Timeline.Write_Index < 1) OR
   (VIO_Timeline.Write_Index >= 64) THEN

    L_Index := 1;

    IF VIO_Timeline.Write_Index >= 64 THEN
        VIO_Timeline.Timeline_Overflow := TRUE;
    END_IF;

ELSE
    L_Index := VIO_Timeline.Write_Index + 1;
END_IF;

// ======================================================
// FRAME STORAGE
// ======================================================
VIO_Timeline.Frames[L_Index] := VI_Frame;
VIO_Timeline.Write_Index := L_Index;

IF VIO_Timeline.Frame_Count < 64 THEN
    VIO_Timeline.Frame_Count :=
        VIO_Timeline.Frame_Count + 1;
END_IF;

// ======================================================
// TELEMETRY UPDATE
// ======================================================
VIO_Timeline.Sequencing_Valid :=
    VI_Frame.Sequencing_Valid;

VIO_Timeline.Ownership_Valid :=
    VI_Frame.Ownership_Valid;

VIO_Timeline.Synchronization_Valid :=
    VI_Frame.Synchronization_Valid;

VIO_Timeline.Runtime_Jitter_Detected :=
    VI_Frame.Runtime_Jitter_Detected;

VIO_Timeline.Runtime_Latency_Detected :=
    VI_Frame.Runtime_Latency_Detected;

VIO_Timeline.Runtime_Degraded :=
    VI_Frame.Runtime_Degraded;

VIO_Timeline.Status_Code := VI_Frame.Status_Code;
VIO_Timeline.Status_Text := VI_Frame.Status_Text;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_Timeline_Observer <<<
