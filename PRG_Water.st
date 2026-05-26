PROGRAM PRG_Water
VAR
    fbProjection : FB_Water_Output_Projection;
    L_Zone_Enable : ARRAY[1..GVL_CONSTANTS.C_MAX_WATER_ZONES] OF BOOL;
    L_Valve_35_Open : BOOL;
    L_Valve_35_Close : BOOL;
    L_Valve_36_Open : BOOL;
    L_Valve_36_Close : BOOL;
    L_Local_Valve_Open : ARRAY[1..6] OF BOOL;
    L_Local_Valve_Close : ARRAY[1..6] OF BOOL;
    L_i : INT;
    L_Projected_Valve_Group : UINT;
END_VAR

// ==============================================================================
// Water runtime output bridge.
//
// Topology:
// - group 1: riser 1 kitchen, local valves 1(HWS/CW) and 2(HW);
// - group 2: riser 2 master bathroom, local valves 3 and 4;
// - group 3: riser 3 guest bathrooms + laundry, local valves 5 and 6;
// - group 4: common inlet 35(CW) and 36(HW).
//
// Normally-open valves are used because water is from a well: no electrical
// power means no pump and no pressurized water. Leak/fallback projects Close;
// HMI emergency-open projects Open for a timed, limited interval.
// ==============================================================================

PRG_Water_Emergency_Open_Manager();

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

FOR L_i := 1 TO 6 DO
    L_Local_Valve_Open[L_i] := FALSE;
    L_Local_Valve_Close[L_i] := FALSE;
END_FOR;

L_Valve_35_Open := FALSE;
L_Valve_35_Close := FALSE;
L_Valve_36_Open := FALSE;
L_Valve_36_Close := FALSE;

IF GVL_INTENT_SAFETY.I_Water_Selective_Recovery_Allowed THEN
    GVL_WATER_DOMAIN_STATUS.G_Recovery_Requested := TRUE;

    IF (GVL_INTENT_SAFETY.I_Water_Recovery_Target_Zone >= 1) AND (GVL_INTENT_SAFETY.I_Water_Recovery_Target_Zone <= GVL_CONSTANTS.C_MAX_WATER_ZONES) THEN
        L_Zone_Enable[GVL_INTENT_SAFETY.I_Water_Recovery_Target_Zone] := TRUE;
    END_IF;
END_IF;

// Existing authoritative common inlet fallback path from command shadow.
L_Valve_35_Close := GVL_COMMAND_SHADOW.G_Close_Valve_35;
L_Valve_36_Close := GVL_COMMAND_SHADOW.G_Close_Valve_36;

// Deterministic water output projection by isolation group.
IF GVL_Water_Output_Projection.G_Runtime_Valid THEN

    IF GVL_Water_Output_Projection.G_Global_Fallback_Projecting THEN
        FOR L_i := 1 TO 6 DO
            L_Local_Valve_Close[L_i] := TRUE;
        END_FOR;
        L_Valve_35_Close := TRUE;
        L_Valve_36_Close := TRUE;
        GVL_WATER_DOMAIN_STATUS.G_Global_Path_Active := TRUE;
    ELSE
        FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_FLOOD_SENSORS DO
            IF GVL_Water_Output_Projection.G_Output_Projection_State[L_i].Projection_Allowed AND
               GVL_Water_Output_Projection.G_Output_Projection_State[L_i].Physical_Close_Project THEN

                L_Projected_Valve_Group := GVL_Water_Output_Projection.G_Output_Projection_State[L_i].Valve_Group_Id;

                CASE L_Projected_Valve_Group OF
                    1:
                        L_Local_Valve_Close[1] := TRUE;
                        L_Local_Valve_Close[2] := TRUE;
                    2:
                        L_Local_Valve_Close[3] := TRUE;
                        L_Local_Valve_Close[4] := TRUE;
                    3:
                        L_Local_Valve_Close[5] := TRUE;
                        L_Local_Valve_Close[6] := TRUE;
                    4:
                        L_Valve_35_Close := TRUE;
                        L_Valve_36_Close := TRUE;
                ELSE
                    L_Valve_35_Close := TRUE;
                    L_Valve_36_Close := TRUE;
                    GVL_WATER_DOMAIN_STATUS.G_Global_Path_Active := TRUE;
                END_CASE;
            END_IF;
        END_FOR;
    END_IF;
END_IF;

// Emergency open for selected riser/common inlet: project Open and suppress
// the corresponding Close command for the timed interval.
IF GVL_WATER_EMERGENCY_OPEN.G_Open_Riser_1_Active THEN
    L_Local_Valve_Close[1] := FALSE;
    L_Local_Valve_Close[2] := FALSE;
    L_Local_Valve_Open[1] := TRUE;
    L_Local_Valve_Open[2] := TRUE;
END_IF;

IF GVL_WATER_EMERGENCY_OPEN.G_Open_Riser_2_Active THEN
    L_Local_Valve_Close[3] := FALSE;
    L_Local_Valve_Close[4] := FALSE;
    L_Local_Valve_Open[3] := TRUE;
    L_Local_Valve_Open[4] := TRUE;
END_IF;

IF GVL_WATER_EMERGENCY_OPEN.G_Open_Riser_3_Active THEN
    L_Local_Valve_Close[5] := FALSE;
    L_Local_Valve_Close[6] := FALSE;
    L_Local_Valve_Open[5] := TRUE;
    L_Local_Valve_Open[6] := TRUE;
END_IF;

IF GVL_WATER_EMERGENCY_OPEN.G_Open_Common_Inlet_Active THEN
    L_Valve_35_Close := FALSE;
    L_Valve_36_Close := FALSE;
    L_Valve_35_Open := TRUE;
    L_Valve_36_Open := TRUE;
END_IF;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_WATER_ZONES DO
    IF L_Zone_Enable[L_i] THEN
        GVL_WATER_DOMAIN_STATUS.G_Any_Zone_Active := TRUE;
    END_IF;
END_FOR;

GVL_WATER_DOMAIN_STATUS.G_Output_35_Active := L_Valve_35_Close OR L_Valve_35_Open;
GVL_WATER_DOMAIN_STATUS.G_Output_36_Active := L_Valve_36_Close OR L_Valve_36_Open;

FOR L_i := 1 TO 6 DO
    IF L_Local_Valve_Close[L_i] OR L_Local_Valve_Open[L_i] THEN
        GVL_WATER_DOMAIN_STATUS.G_Any_Zone_Active := TRUE;
    END_IF;
END_FOR;

GVL_WATER_DOMAIN_STATUS.G_Runtime_Required :=
    GVL_WATER_DOMAIN_STATUS.G_Recovery_Requested
    OR GVL_WATER_DOMAIN_STATUS.G_Global_Path_Active
    OR GVL_WATER_DOMAIN_STATUS.G_Output_35_Active
    OR GVL_WATER_DOMAIN_STATUS.G_Output_36_Active
    OR GVL_WATER_DOMAIN_STATUS.G_Any_Zone_Active;

GVL_WATER_DOMAIN_STATUS.G_Runtime_Idle_By_Design := NOT GVL_WATER_DOMAIN_STATUS.G_Runtime_Required;

IF GVL_WATER_DOMAIN_STATUS.G_Runtime_Idle_By_Design THEN
    GVL_WATER_DOMAIN_STATUS.G_Status_Code := 0;
    GVL_WATER_DOMAIN_STATUS.G_Status_Text := 'Water domain idle by design';
ELSIF GVL_WATER_DOMAIN_STATUS.G_Global_Path_Active THEN
    GVL_WATER_DOMAIN_STATUS.G_Status_Code := 2;
    GVL_WATER_DOMAIN_STATUS.G_Status_Text := 'Water domain global path active';
ELSIF GVL_WATER_EMERGENCY_OPEN.G_Open_Riser_1_Active OR
      GVL_WATER_EMERGENCY_OPEN.G_Open_Riser_2_Active OR
      GVL_WATER_EMERGENCY_OPEN.G_Open_Riser_3_Active OR
      GVL_WATER_EMERGENCY_OPEN.G_Open_Common_Inlet_Active THEN
    GVL_WATER_DOMAIN_STATUS.G_Status_Code := 3;
    GVL_WATER_DOMAIN_STATUS.G_Status_Text := 'Water emergency open active';
ELSE
    GVL_WATER_DOMAIN_STATUS.G_Status_Code := 1;
    GVL_WATER_DOMAIN_STATUS.G_Status_Text := 'Water domain active';
END_IF;

fbProjection(
    VI_Zone_Enable := L_Zone_Enable,
    VI_Valve_35_Open := L_Valve_35_Open,
    VI_Valve_35_Close := L_Valve_35_Close,
    VI_Valve_36_Open := L_Valve_36_Open,
    VI_Valve_36_Close := L_Valve_36_Close,
    VI_Local_Valve_Open := L_Local_Valve_Open,
    VI_Local_Valve_Close := L_Local_Valve_Close
);

PRG_Water_Valve_Diagnostics();

// >>> BULK_SYNC_ANCHOR: PRG_Water <<<
END_PROGRAM
