PROGRAM PRG_Water
VAR
    fbProjection : FB_Water_Output_Projection;
    L_Zone_Enable : ARRAY[1..32] OF BOOL;
    L_Valve_35_Close : BOOL;
    L_Valve_36_Close : BOOL;
    L_i : INT;
END_VAR

// Default: all zones disabled
FOR L_i := 1 TO 32 DO
    L_Zone_Enable[L_i] := FALSE;
END_FOR;

// Selective recovery logic
IF GVL_INTENT_SAFETY.I_Water_Selective_Recovery_Allowed THEN
    IF (GVL_INTENT_SAFETY.I_Water_Recovery_Target_Zone >= 1) AND (GVL_INTENT_SAFETY.I_Water_Recovery_Target_Zone <= 32) THEN
        L_Zone_Enable[GVL_INTENT_SAFETY.I_Water_Recovery_Target_Zone] := TRUE;
    END_IF;
END_IF;

// Valve control from command layer
L_Valve_35_Close := GVL_COMMAND_SHADOW.G_Close_Valve_35;
L_Valve_36_Close := GVL_COMMAND_SHADOW.G_Close_Valve_36;

// Projection
fbProjection(
    VI_Zone_Enable := L_Zone_Enable,
    VI_Valve_35_Close := L_Valve_35_Close,
    VI_Valve_36_Close := L_Valve_36_Close
);

// >>> BULK_SYNC_ANCHOR: PRG_Water <<<
