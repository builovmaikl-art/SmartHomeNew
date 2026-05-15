PROGRAM PRG_PreOutput_Safety_Barrier
VAR
    L_i : INT;
    L_Now_MS : UDINT;
    L_Block_IO : BOOL := FALSE;
    L_Error_Code : UDINT := 0;
    L_Error_Text : STRING(160) := '';
    L_Any_Manifold_Pump_On : BOOL := FALSE;
    L_Prev_Block_IO : BOOL;

    L_Selective_Projection_Active : BOOL;
    L_Global_Fallback_Active : BOOL;
    L_Runtime_Projection_Healthy : BOOL;

    fbLog : FB_LogEvent;
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_Block_IO := FALSE;
L_Error_Code := 0;
L_Error_Text := '';
L_Any_Manifold_Pump_On := FALSE;
L_Prev_Block_IO := GVL_COMMAND_VERIFY.PreOutput_Block_IO;

L_Selective_Projection_Active :=
    GVL_Water_Isolation_Authority.G_Any_Selective_Authority_Allowed;

L_Global_Fallback_Active :=
    GVL_Water_Isolation_Authority.G_Any_Global_Fallback_Required;

L_Runtime_Projection_Healthy :=
    GVL_Water_Output_Reconciliation.G_Runtime_Valid
    AND NOT GVL_Water_Output_Reconciliation.G_Any_Conflict_Detected;

// ======================================================
// PRE-OUTPUT SAFETY BARRIER
// ======================================================
// Runtime order:
// orchestration
//   -> authority arbitration
//   -> projection
//   -> reconciliation
//   -> pre-output barrier
//   -> PRG_IO_Write
//
// Deterministic hard-stop gate before physical IO publication.
// ======================================================

IF (NOT L_Block_IO) AND (NOT GVL_STATUS.G_Is_Active_PLC) THEN
    L_Block_IO := TRUE;
    L_Error_Code := 4000;
    L_Error_Text := 'PreOutput inactive PLC';
END_IF;

IF (NOT L_Block_IO)
   AND (GVL_COMMAND.G_Gas_Valve_Close <> GVL_COMMAND_SHADOW.G_Gas_Valve_Close) THEN

    L_Block_IO := TRUE;
    L_Error_Code := 4001;
    L_Error_Text := 'PreOutput gas command mismatch';
END_IF;

IF (NOT L_Block_IO)
   AND (GVL_COMMAND.G_Boiler_Stop <> GVL_COMMAND_SHADOW.G_Boiler_Stop) THEN

    L_Block_IO := TRUE;
    L_Error_Code := 4002;
    L_Error_Text := 'PreOutput boiler command mismatch';
END_IF;

IF (NOT L_Block_IO)
   AND (GVL_COMMAND.G_Vent_Stop <> GVL_COMMAND_SHADOW.G_Vent_Stop) THEN

    L_Block_IO := TRUE;
    L_Error_Code := 4003;
    L_Error_Text := 'PreOutput vent command mismatch';
END_IF;

IF (NOT L_Block_IO)
   AND (GVL_COMMAND.G_Close_Valve_35 <> GVL_COMMAND_SHADOW.G_Close_Valve_35) THEN

    L_Block_IO := TRUE;
    L_Error_Code := 4004;
    L_Error_Text := 'PreOutput valve 35 command mismatch';
END_IF;

IF (NOT L_Block_IO)
   AND (GVL_COMMAND.G_Close_Valve_36 <> GVL_COMMAND_SHADOW.G_Close_Valve_36) THEN

    L_Block_IO := TRUE;
    L_Error_Code := 4005;
    L_Error_Text := 'PreOutput valve 36 command mismatch';
END_IF;

// GAS safety.
IF (NOT L_Block_IO)
   AND (GVL_SAFETY_SHUTDOWN.G_Safety_Mode = GAS)
   AND (NOT GVL_COMMAND_SHADOW.G_Gas_Valve_Close) THEN

    L_Block_IO := TRUE;
    L_Error_Code := 4010;
    L_Error_Text := 'PreOutput gas valve close missing';
END_IF;

IF (NOT L_Block_IO)
   AND (GVL_SAFETY_SHUTDOWN.G_Safety_Mode = GAS) THEN

    IF (GVL_VENT_OUTPUT.AO_Supply_Fans[1] = 0)
       AND (GVL_VENT_OUTPUT.AO_Exhaust_Fans[1] = 0) THEN

        L_Block_IO := TRUE;
        L_Error_Code := 4011;
        L_Error_Text := 'PreOutput gas ventilation inactive';

    END_IF;
END_IF;

// FIRE safety.
IF (NOT L_Block_IO)
   AND (GVL_SAFETY_SHUTDOWN.G_Safety_Mode = FIRE) THEN

    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_EXHAUST_FANS DO

        IF GVL_VENT_OUTPUT.AO_Exhaust_Fans[L_i] = 0 THEN

            L_Block_IO := TRUE;
            L_Error_Code := 4020;
            L_Error_Text := 'PreOutput smoke exhaust inactive';

        END_IF;

    END_FOR;
END_IF;

IF (NOT L_Block_IO)
   AND (GVL_SAFETY_SHUTDOWN.G_Safety_Mode = FIRE) THEN

    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SUPPLY_FANS DO

        IF GVL_VENT_OUTPUT.AO_Supply_Fans[L_i] <> 0 THEN

            L_Block_IO := TRUE;
            L_Error_Code := 4021;
            L_Error_Text := 'PreOutput supply active in fire';

        END_IF;

    END_FOR;
END_IF;

// WATER runtime safety.
IF (NOT L_Block_IO)
   AND (GVL_SAFETY_SHUTDOWN.G_Safety_Mode = WATER_LEAK) THEN

    // Projection/runtime reconciliation must remain healthy.
    IF NOT L_Runtime_Projection_Healthy THEN

        L_Block_IO := TRUE;
        L_Error_Code := 4030;
        L_Error_Text := 'PreOutput runtime reconciliation invalid';

    // Selective authority path.
    ELSIF L_Selective_Projection_Active THEN

        IF NOT GVL_Water_Output_Projection.G_Any_Close_Projected THEN

            L_Block_IO := TRUE;
            L_Error_Code := 4031;
            L_Error_Text := 'PreOutput selective projection missing';

        END_IF;

    // Conservative global fallback path.
    ELSIF L_Global_Fallback_Active THEN

        IF GVL_COMMAND_SHADOW.G_Close_Valve_35
           AND NOT GVL_WATER_OUTPUT.DO_Water_Valve_35_Close THEN

            L_Block_IO := TRUE;
            L_Error_Code := 4032;
            L_Error_Text := 'PreOutput valve 35 close missing';

        ELSIF GVL_COMMAND_SHADOW.G_Close_Valve_36
              AND NOT GVL_WATER_OUTPUT.DO_Water_Valve_36_Close THEN

            L_Block_IO := TRUE;
            L_Error_Code := 4033;
            L_Error_Text := 'PreOutput valve 36 close missing';

        END_IF;

    ELSE

        L_Block_IO := TRUE;
        L_Error_Code := 4034;
        L_Error_Text := 'PreOutput water authority undefined';

    END_IF;
END_IF;

// FREEZE protection.
IF (NOT L_Block_IO)
   AND GVL_STATE.G_Safety_Freeze_Risk THEN

    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO

        IF GVL_HEATING_OUTPUT.DO_Manifold_Pumps[L_i] THEN
            L_Any_Manifold_Pump_On := TRUE;
        END_IF;

    END_FOR;

    IF (NOT L_Any_Manifold_Pump_On)
       AND (NOT GVL_HEATING_OUTPUT.DO_Backup_Circulation_Pump) THEN

        L_Block_IO := TRUE;
        L_Error_Code := 4040;
        L_Error_Text := 'PreOutput freeze circulation inactive';

    END_IF;
END_IF;

GVL_COMMAND_VERIFY.PreOutput_Barrier_OK := NOT L_Block_IO;
GVL_COMMAND_VERIFY.PreOutput_Block_IO := L_Block_IO;
GVL_COMMAND_VERIFY.PreOutput_Last_Error_Code := L_Error_Code;
GVL_COMMAND_VERIFY.PreOutput_Last_Error_Text := L_Error_Text;

IF L_Block_IO THEN

    GVL_COMMAND_VERIFY.PreOutput_Last_Error_Time_MS := L_Now_MS;

    IF NOT L_Prev_Block_IO THEN

        GVL_COMMAND_VERIFY.PreOutput_Block_Count :=
            GVL_COMMAND_VERIFY.PreOutput_Block_Count + 1;

        fbLog(
            VI_Event_Type := 1002,
            VI_Timestamp := L_Now_MS,
            VI_Param1 := L_Error_Code,
            VI_Param2 := GVL_COMMAND_VERIFY.PreOutput_Block_Count
        );

    END_IF;
END_IF;

END_PROGRAM