PROGRAM PRG_Water
VAR
    fbProjection : FB_Water_Output_Projection;
    L_Zone_Enable : ARRAY[1..GVL_CONSTANTS.C_MAX_WATER_ZONES] OF BOOL;
    L_Valve_35_Close : BOOL;
    L_Valve_36_Close : BOOL;
    L_i : INT;
    L_Projected_Valve_Group : UINT;
END_VAR

// ==============================================================================
// Water runtime output bridge.
//
// GVL_COMMAND_SHADOW remains owned exclusively by PRG_Command_Arbitration.
// This PRG is the water domain output projection bridge into GVL_WATER_OUTPUT.
//
// Priority:
// 1. Existing global safety close command from command shadow.
// 2. Deterministic water output projection if valid.
//
// This PRG does not perform leak classification, topology decisions,
// diagnostics, or recovery governance.
// ==============================================================================

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_WATER_ZONES DO
    L_Zone_Enable[L_i] := FALSE;
END_FOR;

IF GVL_INTENT_SAFETY.I_Water_Selective_Recovery_Allowed THEN
    IF (GVL_INTENT_SAFETY.I_Water_Recovery_Target_Zone >= 1) AND (GVL_INTENT_SAFETY.I_Water_Recovery_Target_Zone <= GVL_CONSTANTS.C_MAX_WATER_ZONES) THEN
        L_Zone_Enable[GVL_INTENT_SAFETY.I_Water_Recovery_Target_Zone] := TRUE;
    END_IF;
END_IF;

// Existing authoritative global fallback path.
L_Valve_35_Close := GVL_COMMAND_SHADOW.G_Close_Valve_35;
L_Valve_36_Close := GVL_COMMAND_SHADOW.G_Close_Valve_36;

// Deterministic projection bridge.
// Conservative global fallback projection dominates selective projection.
IF GVL_Water_Output_Projection.G_Runtime_Valid THEN

    IF GVL_Water_Output_Projection.G_Global_Fallback_Projecting THEN
        L_Valve_35_Close := TRUE;
        L_Valve_36_Close := TRUE;
    ELSE
        FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_FLOOD_SENSORS DO
            IF GVL_Water_Output_Projection.G_Output_Projection_State[L_i].Projection_Allowed AND
               GVL_Water_Output_Projection.G_Output_Projection_State[L_i].Physical_Close_Project THEN

                L_Projected_Valve_Group :=
                    GVL_Water_Output_Projection.G_Output_Projection_State[L_i].Valve_Group_Id;

                CASE L_Projected_Valve_Group OF
                    1:
                        L_Valve_35_Close := TRUE;
                    2:
                        L_Valve_36_Close := TRUE;
                    3:
                        L_Valve_35_Close := TRUE;
                        L_Valve_36_Close := TRUE;
                ELSE
                    // Unknown valve group is not projected here.
                    // Conservative fallback is handled by authority/projection layers.
                END_CASE;
            END_IF;
        END_FOR;
    END_IF;
END_IF;

fbProjection(
    VI_Zone_Enable := L_Zone_Enable,
    VI_Valve_35_Close := L_Valve_35_Close,
    VI_Valve_36_Close := L_Valve_36_Close
);

// >>> BULK_SYNC_ANCHOR: PRG_Water <<<
END_PROGRAM
