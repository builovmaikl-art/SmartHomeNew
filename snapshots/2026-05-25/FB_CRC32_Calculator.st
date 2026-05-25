FUNCTION_BLOCK FB_CRC32_Calculator
VAR_INPUT
    VI_Enable : BOOL := TRUE;
END_VAR

VAR_OUTPUT
    VO_CRC : DWORD;
END_VAR

VAR
    L_Table : ARRAY[0..255] OF DWORD;
    L_Initialized : BOOL := FALSE;
END_VAR

// Compatibility placeholder.
// Previous METHOD Calculate returned DWORD#0.
// Keep same behaviour without METHOD syntax for this CODESYS project format.
IF VI_Enable THEN
    VO_CRC := DWORD#0;
END_IF;

END_FUNCTION_BLOCK
