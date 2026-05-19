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

GVL_WATER_DOMAIN_STATUS.G_Runtime_Required := FALSE;
GVL_WATER_DOMAIN_STATUS.G_Runtime_Executed := TRUE;
GVL_WATER_DOMAIN_STATUS.G_Runtime_Idle_By_Design := FALSE;
GVL_WATER_DOMAIN_STATUS.G_Recovery_Requested := FALSE;
GVL_WATER_DOMAIN_STATUS.G_Global_Path_Active := FALSE;
GVL_WATER_DOMAIN_STATUS.G_Output_35_Active := FALSE;
GVL_WATER_DOMAIN_STATUS.G_Output_36_Active := FALSE;
GVL_WATER_DOMAIN_STATUS.G_Any_Zone_Active := FALSE;
GVL_WATER_DOMAIN_STATUS.G_Last_Update_MS := GVL_STATUS.G_System_Time_MS;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_WATER_ZONES DO
    L_Zone_Enable[L_i] := FALSE;
END_FOR;

IF GVL_INTENT_SAFETY.I_Water_Selective_Recovery_Allowed THEN
    GVL_WATER_DOMAIN_STATUS.G_Recovery_Requested := TRUE;

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
        GVL_WATER_DOMAIN_STATUS.G_Global_Path_Active := TRUE;
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

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_WATER_ZONES DO
    IF L_Zone_Enable[L_i] THEN
        GVL_WATER_DOMAIN_STATUS.G_Any_Zone_Active := TRUE;
    END_IF;
END_FOR;

GVL_WATER_DOMAIN_STATUS.G_Output_35_Active := L_Valve_35_Close;
GVL_WATER_DOMAIN_STATUS.G_Output_36_Active := L_Valve_36_Close;

GVL_WATER_DOMAIN_STATUS.G_Runtime_Required :=
    GVL_WATER_DOMAIN_STATUS.G_Recovery_Requested
    OR GVL_WATER_DOMAIN_STATUS.G_Global_Path_Active
    OR GVL_WATER_DOMAIN_STATUS.G_Output_35_Active
    OR GVL_WATER_DOMAIN_STATUS.G_Output_36_Active
    OR GVL_WATER_DOMAIN_STATUS.G_Any_Zone_Active;

GVL_WATER_DOMAIN_STATUS.G_Runtime_Idle_By_Design :=
    NOT GVL_WATER_DOMAIN_STATUS.G_Runtime_Required;

IF GVL_WATER_DOMAIN_STATUS.G_Runtime_Idle_By_Design THEN
    GVL_WATER_DOMAIN_STATUS.G_Status_Code := 0;
    GVL_WATER_DOMAIN_STATUS.G_Status_Text := 'Water domain idle by design';
ELSIF GVL_WATER_DOMAIN_STATUS.G_Global_Path_Active THEN
    GVL_WATER_DOMAIN_STATUS.G_Status_Code := 2;
    GVL_WATER_DOMAIN_STATUS.G_Status_Text := 'Water domain global path active';
ELSE
    GVL_WATER_DOMAIN_STATUS.G_Status_Code := 1;
    GVL_WATER_DOMAIN_STATUS.G_Status_Text := 'Water domain active';
END_IF;

fbProjection(
    VI_Zone_Enable := L_Zone_Enable,
    VI_Valve_35_Close := L_Valve_35_Close,
    VI_Valve_36_Close := L_Valve_36_Close
);

// >>> BULK_SYNC_ANCHOR: PRG_Water <<<
END_PROGRAM
