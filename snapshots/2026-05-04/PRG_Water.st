PROGRAM PRG_Water
VAR
    fbProjection : FB_Water_Output_Projection;
    L_Zone_Enable : ARRAY[1..GVL_CONSTANTS.C_MAX_WATER_ZONES] OF BOOL;
    L_Valve_35_Close : BOOL;
    L_Valve_36_Close : BOOL;
    L_i : INT;
END_VAR

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_WATER_ZONES DO
    L_Zone_Enable[L_i] := FALSE;
END_FOR;

IF GVL_INTENT_SAFETY.I_Water_Selective_Recovery_Allowed THEN
    IF (GVL_INTENT_SAFETY.I_Water_Recovery_Target_Zone >= 1) AND (GVL_INTENT_SAFETY.I_Water_Recovery_Target_Zone <= GVL_CONSTANTS.C_MAX_WATER_ZONES) THEN
        L_Zone_Enable[GVL_INTENT_SAFETY.I_Water_Recovery_Target_Zone] := TRUE;
    END_IF;
END_IF;

L_Valve_35_Close := GVL_COMMAND_SHADOW.G_Close_Valve_35;
L_Valve_36_Close := GVL_COMMAND_SHADOW.G_Close_Valve_36;

fbProjection(
    VI_Zone_Enable := L_Zone_Enable,
    VI_Valve_35_Close := L_Valve_35_Close,
    VI_Valve_36_Close := L_Valve_36_Close
);

// >>> BULK_SYNC_ANCHOR: PRG_Water <<<
