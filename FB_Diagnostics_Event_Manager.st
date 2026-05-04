FUNCTION_BLOCK FB_Diagnostics_Event_Manager
VAR_INPUT
    VI_Code : UDINT;
    VI_Severity : INT;
    VI_Active : BOOL;
    VI_Timestamp : UDINT;
    VI_Source : INT;
END_VAR
VAR_IN_OUT
    VIO_Events : ARRAY[1..50] OF ST_Diagnostic_Event;
    VIO_Count : INT;
END_VAR
VAR
    L_Index : INT;
    L_i : INT;
    L_Found_Index : INT;
    L_Was_Active : BOOL;
    L_Debounce_Index : INT;
    L_Free_Debounce_Index : INT;
    L_Stable_State : BOOL;

    // Per-event anti-flapping state, keyed by (Code, Source)
    L_Debounce_Used : ARRAY[1..50] OF BOOL;
    L_Debounce_Code : ARRAY[1..50] OF UDINT;
    L_Debounce_Source : ARRAY[1..50] OF INT;
    L_Debounce_Last_Input_State : ARRAY[1..50] OF BOOL;
    L_Debounce_Stable_State : ARRAY[1..50] OF BOOL;
    L_Debounce_Last_Change_Time : ARRAY[1..50] OF UDINT;
END_VAR

// ======================================================
// FIND EXISTING EVENT
// ======================================================
L_Found_Index := 0;
L_Was_Active := FALSE;

FOR L_i := 1 TO 50 DO
    IF (VIO_Events[L_i].Code = VI_Code) AND (VIO_Events[L_i].Source = VI_Source) THEN
        L_Found_Index := L_i;
        L_Was_Active := VIO_Events[L_i].Active;
        EXIT;
    END_IF;
END_FOR;

// ======================================================
// FIND / ALLOCATE PER-EVENT DEBOUNCE SLOT
// ======================================================
L_Debounce_Index := 0;
L_Free_Debounce_Index := 0;

FOR L_i := 1 TO 50 DO
    IF L_Debounce_Used[L_i] THEN
        IF (L_Debounce_Code[L_i] = VI_Code) AND (L_Debounce_Source[L_i] = VI_Source) THEN
            L_Debounce_Index := L_i;
            EXIT;
        END_IF;
    ELSIF L_Free_Debounce_Index = 0 THEN
        L_Free_Debounce_Index := L_i;
    END_IF;
END_FOR;

IF L_Debounce_Index = 0 THEN
    IF L_Free_Debounce_Index > 0 THEN
        L_Debounce_Index := L_Free_Debounce_Index;
    ELSE
        // Deterministic fallback if debounce table is full.
        L_Debounce_Index := (VIO_Count MOD 50) + 1;
    END_IF;

    L_Debounce_Used[L_Debounce_Index] := TRUE;
    L_Debounce_Code[L_Debounce_Index] := VI_Code;
    L_Debounce_Source[L_Debounce_Index] := VI_Source;
    L_Debounce_Last_Input_State[L_Debounce_Index] := VI_Active;
    L_Debounce_Stable_State[L_Debounce_Index] := FALSE;
    L_Debounce_Last_Change_Time[L_Debounce_Index] := VI_Timestamp;
END_IF;

// ======================================================
// PER-EVENT ANTI-FLAPPING (2s debounce)
// ======================================================
IF VI_Active <> L_Debounce_Last_Input_State[L_Debounce_Index] THEN
    L_Debounce_Last_Input_State[L_Debounce_Index] := VI_Active;
    L_Debounce_Last_Change_Time[L_Debounce_Index] := VI_Timestamp;
END_IF;

IF (VI_Timestamp - L_Debounce_Last_Change_Time[L_Debounce_Index]) > 2000 THEN
    L_Debounce_Stable_State[L_Debounce_Index] := L_Debounce_Last_Input_State[L_Debounce_Index];
END_IF;

L_Stable_State := L_Debounce_Stable_State[L_Debounce_Index];

// ======================================================
// APPLY ONLY STABLE STATE
// ======================================================
IF L_Stable_State THEN
    IF NOT L_Was_Active THEN
        L_Index := (VIO_Count MOD 50) + 1;
        VIO_Events[L_Index].Code := VI_Code;
        VIO_Events[L_Index].Severity := VI_Severity;
        VIO_Events[L_Index].Active := TRUE;
        VIO_Events[L_Index].Timestamp := VI_Timestamp;
        VIO_Events[L_Index].Source := VI_Source;
        VIO_Count := VIO_Count + 1;
    ELSIF L_Found_Index > 0 THEN
        VIO_Events[L_Found_Index].Severity := VI_Severity;
    END_IF;
ELSE
    IF L_Found_Index > 0 THEN
        VIO_Events[L_Found_Index].Active := FALSE;
    END_IF;
END_IF;

// >>> BULK_SYNC_ANCHOR: FB_Diagnostics_Event_Manager <<<
