FUNCTION_BLOCK FB_Command_Deduplication
VAR_INPUT
    VI_Command_ID : UDINT; // Unique ID from Gateway/HMI
    VI_Command_Type : E_Gateway_Command_Type;
    VI_Command_Value : REAL;
    VI_System_Time_MS : UDINT;
END_VAR
VAR_OUTPUT
    VO_Is_New_Command : BOOL; // TRUE if this command should be executed
    VO_Processed_ID : UDINT;
END_VAR
VAR
    L_Processed_History : ARRAY[0..GVL_CONSTANTS.C_MAX_DEDUPLICATION_HISTORY-1] OF UDINT; // Ring buffer of last processed IDs
    L_Processed_Times   : ARRAY[0..GVL_CONSTANTS.C_MAX_DEDUPLICATION_HISTORY-1] OF UDINT; // Timestamps for processed IDs
    L_History_Index : INT := 0;
    L_i : INT;
    L_Found : BOOL;
END_VAR

// Check if command ID is already in history
L_Found := FALSE;
FOR L_i := 0 TO GVL_CONSTANTS.C_MAX_DEDUPLICATION_HISTORY-1 DO
    IF L_Processed_History[L_i] = VI_Command_ID AND VI_Command_ID <> 0 THEN
        // Check if the command is not too old (e.g., 1 hour = 3600000 ms)
        IF (VI_System_Time_MS - L_Processed_Times[L_i]) < 3600000 THEN
            L_Found := TRUE;
            EXIT;
        END_IF;
    END_IF;
END_FOR;

IF NOT L_Found AND VI_Command_ID <> 0 THEN
    // New command detected
    VO_Is_New_Command := TRUE;
    VO_Processed_ID := VI_Command_ID;
    
    // Add to history
    L_Processed_History[L_History_Index] := VI_Command_ID;
    L_Processed_Times[L_History_Index] := VI_System_Time_MS;
    L_History_Index := L_History_Index + 1;
    IF L_History_Index > GVL_CONSTANTS.C_MAX_DEDUPLICATION_HISTORY-1 THEN
        L_History_Index := 0;
    END_IF;
ELSE
    // Duplicate or empty command
    VO_Is_New_Command := FALSE;
    VO_Processed_ID := 0;
END_IF;
END_FUNCTION_BLOCK
