PROGRAM PRG_Water_Valve_Diagnostics
VAR
    L_i : INT;
    L_Now_MS : UDINT;
    L_Timeout_MS : UDINT;
    L_Elapsed_MS : UDINT;
    L_Any_Fault : BOOL;
    L_Any_Close_Fault : BOOL;
    L_Any_Open_Block : BOOL;
    L_First_Close_Fault : INT;
    L_First_Open_Block : INT;
    L_Open_Command : ARRAY[1..8] OF BOOL;
    L_Close_Command : ARRAY[1..8] OF BOOL;
    L_Last_Open_Command : ARRAY[1..8] OF BOOL;
    L_Last_Close_Command : ARRAY[1..8] OF BOOL;
    L_Open_Start_MS : ARRAY[1..8] OF UDINT;
    L_Close_Start_MS : ARRAY[1..8] OF UDINT;
END_VAR

L_Now_MS := GVL_TIME_SERVICE.G_Now_MS;
L_Timeout_MS := GVL_CONSTANTS.C_MS_IN_SECOND * 10;
L_Any_Fault := FALSE;
L_Any_Close_Fault := FALSE;
L_Any_Open_Block := FALSE;
L_First_Close_Fault := 0;
L_First_Open_Block := 0;

GVL_WATER_VALVE_SERVICE.G_Last_Reset_Accepted := FALSE;
GVL_WATER_VALVE_SERVICE.G_Last_Reset_Denied := FALSE;
GVL_WATER_VALVE_SERVICE.G_Last_Reset_Denial_Code := 0;

IF GVL_WATER_VALVE_SERVICE.G_Reset_Confirm THEN
    IF GVL_INTENT_USER.I_User_Access_Level < 2 THEN
        GVL_WATER_VALVE_SERVICE.G_Last_Reset_Denied := TRUE;
        GVL_WATER_VALVE_SERVICE.G_Last_Reset_Denial_Code := 1;
        GVL_WATER_VALVE_SERVICE.G_Status_Text := 'Water valve reset denied: access level < 2';
    ELSE
        IF GVL_WATER_VALVE_SERVICE.G_Reset_All_Open_Blocks_Request THEN
            FOR L_i := 1 TO 8 DO
                GVL_STATUS.G_Diagnostics.Water_Zone_Open_Blocked[L_i] := FALSE;
                GVL_STATUS.G_Diagnostics.Water_Zone_Open_Fault[L_i] := FALSE;
                GVL_WATER_VALVE_SERVICE.G_Reset_Open_Block_Request[L_i] := FALSE;
            END_FOR;
            GVL_WATER_VALVE_SERVICE.G_Last_Reset_Accepted := TRUE;
            GVL_WATER_VALVE_SERVICE.G_Last_Reset_Valve_Index := 0;
            GVL_WATER_VALVE_SERVICE.G_Last_Reset_MS := L_Now_MS;
            GVL_WATER_VALVE_SERVICE.G_Status_Text := 'All water valve open blocks reset';
        ELSE
            FOR L_i := 1 TO 8 DO
                IF GVL_WATER_VALVE_SERVICE.G_Reset_Open_Block_Request[L_i] THEN
                    GVL_STATUS.G_Diagnostics.Water_Zone_Open_Blocked[L_i] := FALSE;
                    GVL_STATUS.G_Diagnostics.Water_Zone_Open_Fault[L_i] := FALSE;
                    GVL_WATER_VALVE_SERVICE.G_Reset_Open_Block_Request[L_i] := FALSE;
                    GVL_WATER_VALVE_SERVICE.G_Last_Reset_Accepted := TRUE;
                    GVL_WATER_VALVE_SERVICE.G_Last_Reset_Valve_Index := L_i;
                    GVL_WATER_VALVE_SERVICE.G_Last_Reset_MS := L_Now_MS;
                    GVL_WATER_VALVE_SERVICE.G_Status_Text := 'Water valve open block reset';
                END_IF;
            END_FOR;
        END_IF;

        IF NOT GVL_WATER_VALVE_SERVICE.G_Last_Reset_Accepted THEN
            GVL_WATER_VALVE_SERVICE.G_Last_Reset_Denied := TRUE;
            GVL_WATER_VALVE_SERVICE.G_Last_Reset_Denial_Code := 2;
            GVL_WATER_VALVE_SERVICE.G_Status_Text := 'Water valve reset denied: no target';
        END_IF;
    END_IF;

    GVL_WATER_VALVE_SERVICE.G_Reset_All_Open_Blocks_Request := FALSE;
    GVL_WATER_VALVE_SERVICE.G_Reset_Confirm := FALSE;
END_IF;

FOR L_i := 1 TO 6 DO
    L_Open_Command[L_i] := GVL_WATER_OUTPUT.DO_Water_Local_Valve_Open[L_i];
    L_Close_Command[L_i] := GVL_WATER_OUTPUT.DO_Water_Local_Valve_Close[L_i];
END_FOR;

L_Open_Command[7] := GVL_WATER_OUTPUT.DO_Water_Valve_35_Open;
L_Close_Command[7] := GVL_WATER_OUTPUT.DO_Water_Valve_35_Close;
L_Open_Command[8] := GVL_WATER_OUTPUT.DO_Water_Valve_36_Open;
L_Close_Command[8] := GVL_WATER_OUTPUT.DO_Water_Valve_36_Close;

FOR L_i := 1 TO 8 DO
    IF L_Open_Command[L_i] AND NOT L_Last_Open_Command[L_i] THEN
        L_Open_Start_MS[L_i] := L_Now_MS;
    END_IF;

    IF L_Close_Command[L_i] AND NOT L_Last_Close_Command[L_i] THEN
        L_Close_Start_MS[L_i] := L_Now_MS;
    END_IF;

    IF L_Open_Command[L_i] THEN
        IF GVL_STATE.G_Water_Zone_Open_FB[L_i] THEN
            GVL_STATUS.G_Diagnostics.Water_Zone_Open_Fault[L_i] := FALSE;
        ELSE
            IF L_Now_MS >= L_Open_Start_MS[L_i] THEN
                L_Elapsed_MS := L_Now_MS - L_Open_Start_MS[L_i];
            ELSE
                L_Elapsed_MS := (4294967295 - L_Open_Start_MS[L_i]) + L_Now_MS + 1;
            END_IF;

            IF L_Elapsed_MS >= L_Timeout_MS THEN
                GVL_STATUS.G_Diagnostics.Water_Zone_Open_Fault[L_i] := TRUE;
                GVL_STATUS.G_Diagnostics.Water_Zone_Open_Blocked[L_i] := TRUE;
            ELSE
                GVL_STATUS.G_Diagnostics.Water_Zone_Open_Fault[L_i] := FALSE;
            END_IF;
        END_IF;
    ELSE
        GVL_STATUS.G_Diagnostics.Water_Zone_Open_Fault[L_i] := FALSE;
    END_IF;

    IF L_Close_Command[L_i] THEN
        IF GVL_STATE.G_Water_Zone_Close_FB[L_i] THEN
            GVL_STATUS.G_Diagnostics.Water_Zone_Close_Fault[L_i] := FALSE;
            GVL_STATUS.G_Diagnostics.Water_Zone_Critical_Close_Fault[L_i] := FALSE;
        ELSE
            IF L_Now_MS >= L_Close_Start_MS[L_i] THEN
                L_Elapsed_MS := L_Now_MS - L_Close_Start_MS[L_i];
            ELSE
                L_Elapsed_MS := (4294967295 - L_Close_Start_MS[L_i]) + L_Now_MS + 1;
            END_IF;
            GVL_STATUS.G_Diagnostics.Water_Zone_Close_Fault[L_i] := L_Elapsed_MS >= L_Timeout_MS;
            GVL_STATUS.G_Diagnostics.Water_Zone_Critical_Close_Fault[L_i] := L_Elapsed_MS >= L_Timeout_MS;
        END_IF;
    ELSE
        GVL_STATUS.G_Diagnostics.Water_Zone_Close_Fault[L_i] := FALSE;
        GVL_STATUS.G_Diagnostics.Water_Zone_Critical_Close_Fault[L_i] := FALSE;
    END_IF;

    IF GVL_STATUS.G_Diagnostics.Water_Zone_Open_Fault[L_i] OR GVL_STATUS.G_Diagnostics.Water_Zone_Close_Fault[L_i] THEN
        L_Any_Fault := TRUE;
    END_IF;

    IF GVL_STATUS.G_Diagnostics.Water_Zone_Open_Blocked[L_i] THEN
        L_Any_Open_Block := TRUE;
        IF L_First_Open_Block = 0 THEN
            L_First_Open_Block := L_i;
        END_IF;
    END_IF;

    IF GVL_STATUS.G_Diagnostics.Water_Zone_Critical_Close_Fault[L_i] THEN
        L_Any_Close_Fault := TRUE;
        IF L_First_Close_Fault = 0 THEN
            L_First_Close_Fault := L_i;
        END_IF;
    END_IF;

    L_Last_Open_Command[L_i] := L_Open_Command[L_i];
    L_Last_Close_Command[L_i] := L_Close_Command[L_i];
END_FOR;

GVL_STATUS.G_Diagnostics.Water_Open_Block_Active := L_Any_Open_Block;
GVL_STATUS.G_Diagnostics.Water_Close_Fault_Active := L_Any_Close_Fault;
GVL_STATUS.G_Diagnostics.Water_Main_Shutdown_Recommended := L_Any_Close_Fault;
GVL_STATUS.G_Diagnostics.Water_Localization_Failed := L_Any_Close_Fault;

IF L_Any_Open_Block THEN
    GVL_STATUS.G_Diagnostics.Water_Open_Block_Text := 'Water valve automatic opening blocked after open timeout';
ELSIF NOT L_Any_Fault THEN
    GVL_STATUS.G_Diagnostics.Water_Open_Block_Text := '';
END_IF;

IF L_Any_Close_Fault THEN
    GVL_STATUS.G_Diagnostics.Water_Close_Fault_Text := 'Water valve close feedback timeout';
    GVL_STATUS.G_Diagnostics.Water_Escalation_Text := 'Water close fault: common inlet fallback recommended';
    IF L_First_Close_Fault <= 6 THEN
        GVL_STATUS.G_Diagnostics.Water_Close_Fault_Zone_Name := 'Local water valve';
    ELSE
        GVL_STATUS.G_Diagnostics.Water_Close_Fault_Zone_Name := 'Common inlet valve';
    END_IF;
ELSIF NOT L_Any_Fault THEN
    GVL_STATUS.G_Diagnostics.Water_Close_Fault_Text := '';
    GVL_STATUS.G_Diagnostics.Water_Escalation_Text := '';
    GVL_STATUS.G_Diagnostics.Water_Close_Fault_Zone_Name := '';
END_IF;

// >>> BULK_SYNC_ANCHOR: PRG_Water_Valve_Diagnostics <<<
END_PROGRAM
