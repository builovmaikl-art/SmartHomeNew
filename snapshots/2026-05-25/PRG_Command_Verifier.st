PROGRAM PRG_Command_Verifier
VAR
    L_i : INT;
    L_Runtime_Error : BOOL := FALSE;
    L_Runtime_Error_Code : UDINT := 0;
    L_Runtime_Error_Text : STRING(160) := '';
    L_Now_MS : UDINT;
    L_Prev_Runtime_Error : BOOL;
    L_Any_Manifold_Pump_On : BOOL;
    L_Any_Vent_Fan_On : BOOL;
    fbLog : FB_LogEvent;
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;

GVL_COMMAND_VERIFY.Command_Mismatch_Count := 0;
GVL_COMMAND_VERIFY.Command_Match_OK := TRUE;
GVL_COMMAND_VERIFY.Command_Mismatch_Active := FALSE;

L_Runtime_Error := FALSE;
L_Runtime_Error_Code := 0;
L_Runtime_Error_Text := '';
L_Any_Manifold_Pump_On := FALSE;
L_Any_Vent_Fan_On := FALSE;

IF (NOT L_Runtime_Error) AND (NOT GVL_STATUS.G_Is_Active_PLC) THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
        IF GVL_IO.DO_Zone_Valves[L_i] THEN
            L_Runtime_Error := TRUE;
            L_Runtime_Error_Code := 10;
            L_Runtime_Error_Text := 'PLC inactive zone valve on';
        END_IF;
    END_FOR;
END_IF;

IF (NOT L_Runtime_Error) AND (NOT GVL_STATUS.G_Is_Active_PLC) THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
        IF GVL_IO.DO_Manifold_Pumps[L_i] THEN
            L_Runtime_Error := TRUE;
            L_Runtime_Error_Code := 11;
            L_Runtime_Error_Text := 'PLC inactive pump on';
        END_IF;
    END_FOR;
END_IF;

IF (NOT L_Runtime_Error) AND (GVL_SAFETY_SHUTDOWN.G_Safety_Mode = GAS) AND (NOT GVL_IO.DO_Gas_Valve_Close) THEN
    L_Runtime_Error := TRUE;
    L_Runtime_Error_Code := 1;
    L_Runtime_Error_Text := 'Gas valve not closed';
END_IF;

IF (NOT L_Runtime_Error) AND (GVL_SAFETY_SHUTDOWN.G_Safety_Mode = GAS) THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SUPPLY_FANS DO
        IF GVL_IO.AO_Supply_Fans[L_i] <> 0 THEN
            L_Any_Vent_Fan_On := TRUE;
        END_IF;
    END_FOR;

    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_EXHAUST_FANS DO
        IF GVL_IO.AO_Exhaust_Fans[L_i] <> 0 THEN
            L_Any_Vent_Fan_On := TRUE;
        END_IF;
    END_FOR;

    IF NOT L_Any_Vent_Fan_On THEN
        L_Runtime_Error := TRUE;
        L_Runtime_Error_Code := 3;
        L_Runtime_Error_Text := 'Gas ventilation inactive';
    END_IF;
END_IF;

IF (NOT L_Runtime_Error) AND (GVL_SAFETY_SHUTDOWN.G_Safety_Mode = FIRE) THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_EXHAUST_FANS DO
        IF GVL_IO.AO_Exhaust_Fans[L_i] = 0 THEN
            L_Runtime_Error := TRUE;
            L_Runtime_Error_Code := 2;
            L_Runtime_Error_Text := 'Smoke exhaust not active';
        END_IF;
    END_FOR;
END_IF;

IF (NOT L_Runtime_Error) AND (GVL_SAFETY_SHUTDOWN.G_Safety_Mode = FIRE) THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SUPPLY_FANS DO
        IF GVL_IO.AO_Supply_Fans[L_i] <> 0 THEN
            L_Runtime_Error := TRUE;
            L_Runtime_Error_Code := 4;
            L_Runtime_Error_Text := 'Supply fan active in fire';
        END_IF;
    END_FOR;
END_IF;

IF (NOT L_Runtime_Error) AND (GVL_SAFETY_SHUTDOWN.G_Safety_Mode = WATER_LEAK) THEN
    IF GVL_COMMAND_SHADOW.G_Close_Valve_35 AND (NOT GVL_IO.DO_Water_Valve_35_Close) THEN
        L_Runtime_Error := TRUE;
        L_Runtime_Error_Code := 5;
        L_Runtime_Error_Text := 'Water valve 35 not closed';
    ELSIF GVL_COMMAND_SHADOW.G_Close_Valve_36 AND (NOT GVL_IO.DO_Water_Valve_36_Close) THEN
        L_Runtime_Error := TRUE;
        L_Runtime_Error_Code := 6;
        L_Runtime_Error_Text := 'Water valve 36 not closed';
    END_IF;
END_IF;

IF (NOT L_Runtime_Error) AND GVL_STATE.G_Safety_Freeze_Risk THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
        IF GVL_IO.DO_Manifold_Pumps[L_i] THEN
            L_Any_Manifold_Pump_On := TRUE;
        END_IF;
    END_FOR;

    IF (NOT L_Any_Manifold_Pump_On) AND (NOT GVL_IO.DO_Backup_Circulation_Pump) THEN
        L_Runtime_Error := TRUE;
        L_Runtime_Error_Code := 7;
        L_Runtime_Error_Text := 'Freeze circulation inactive';
    END_IF;
END_IF;

IF (NOT L_Runtime_Error) AND GVL_STATE.G_Safety_Freeze_Risk AND GVL_COMMAND_SHADOW.G_Heating_Gas_Safety_Stop THEN
    IF GVL_IO.DO_DHW_Heating_Pump THEN
        L_Runtime_Error := TRUE;
        L_Runtime_Error_Code := 8;
        L_Runtime_Error_Text := 'DHW heating active during gas freeze';
    END_IF;
END_IF;

IF L_Runtime_Error THEN
    GVL_COMMAND_VERIFY.Runtime_Sanity_OK := FALSE;
    GVL_COMMAND_VERIFY.Runtime_Last_Error_Code := L_Runtime_Error_Code;
    GVL_COMMAND_VERIFY.Runtime_Last_Error_Text := L_Runtime_Error_Text;
    GVL_COMMAND_VERIFY.Runtime_Last_Error_Time_MS := L_Now_MS;

    IF NOT L_Prev_Runtime_Error THEN
        GVL_COMMAND_VERIFY.Runtime_Sanity_Error_Count := GVL_COMMAND_VERIFY.Runtime_Sanity_Error_Count + 1;
        fbLog(
            VI_Event_Type := 1001,
            VI_Timestamp := L_Now_MS,
            VI_Param1 := L_Runtime_Error_Code,
            VI_Param2 := GVL_COMMAND_VERIFY.Runtime_Sanity_Error_Count
        );
    END_IF;
ELSE
    GVL_COMMAND_VERIFY.Runtime_Sanity_OK := TRUE;
END_IF;

L_Prev_Runtime_Error := L_Runtime_Error;

END_PROGRAM
