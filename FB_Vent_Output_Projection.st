FUNCTION_BLOCK FB_Vent_Output_Projection
VAR_INPUT
    VI_Supply_Fans : ARRAY[1..GVL_CONSTANTS.C_MAX_SUPPLY_FANS] OF BYTE;
    VI_Exhaust_Fans : ARRAY[1..GVL_CONSTANTS.C_MAX_EXHAUST_FANS] OF BYTE;
END_VAR
VAR
    L_i : INT;
    L_Any_Fan_Active : BOOL;
END_VAR

// Convert ventilation manager BYTE outputs directly into IO-ready projection.
// PRG_Ventilation no longer needs to publish fan actuator values through GVL_STATE.

L_Any_Fan_Active := FALSE;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SUPPLY_FANS DO
    GVL_VENT_OUTPUT.AO_Supply_Fans[L_i] := BYTE_TO_UINT(VI_Supply_Fans[L_i]) * 10;
    IF VI_Supply_Fans[L_i] > 0 THEN
        L_Any_Fan_Active := TRUE;
    END_IF;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_EXHAUST_FANS DO
    GVL_VENT_OUTPUT.AO_Exhaust_Fans[L_i] := BYTE_TO_UINT(VI_Exhaust_Fans[L_i]) * 10;
    IF VI_Exhaust_Fans[L_i] > 0 THEN
        L_Any_Fan_Active := TRUE;
    END_IF;
END_FOR;

GVL_VENT_OUTPUT.DO_Vent_Enable := L_Any_Fan_Active;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Vent_Output_Projection <<<
