PROGRAM PRG_IO_Write_Phase_02_Hard_Stop_Safe_State
// IO write phase 02: publish hard-stop safe physical outputs.
VAR
    L_i : INT;
    L_Prev_Distributed_Publication_Block : BOOL;
    L_Prev_Output_Publication_Block : BOOL;
    fbTrace : FB_Trace_Write;
END_VAR

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
    GVL_IO.DO_Zone_Valves[L_i] := FALSE;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    GVL_IO.DO_Manifold_Pumps[L_i] := FALSE;
    GVL_IO.AO_Manifold_Valves[L_i] := 0;
END_FOR;

GVL_IO.DO_DHW_Heating_Pump := FALSE;
GVL_IO.DO_DHW_Circ_Pump := FALSE;
GVL_IO.DO_Backup_Circulation_Pump := FALSE;
GVL_IO.DO_Electric_Heater_Enable := FALSE;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SUPPLY_FANS DO
    GVL_IO.AO_Supply_Fans[L_i] := 0;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_EXHAUST_FANS DO
    GVL_IO.AO_Exhaust_Fans[L_i] := 0;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_WATER_ZONES DO
    GVL_IO.DO_Water_Zone_Enable[L_i] := FALSE;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_LIGHT_ZONES DO
    GVL_IO.AO_Lighting_Levels[L_i] := 0;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BLINDS DO
    GVL_IO.AO_Blinds_Positions[L_i] := 1000;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SOCKETS DO
    GVL_IO.DO_Sockets[L_i] := FALSE;
END_FOR;

GVL_IO.DO_Gate_Open := FALSE;
GVL_IO.DO_Wicket_Open := FALSE;
GVL_IO.DO_Lock_1_Open := FALSE;
GVL_IO.DO_Lock_1_Close := FALSE;
GVL_IO.DO_Lock_2_Open := FALSE;
GVL_IO.DO_Lock_2_Close := FALSE;

// Water hard-stop safe state: cancel all open commands and command closing for
// all local riser valves plus common inlet 35/36.
GVL_IO.DO_Water_Valve_35_Open := FALSE;
GVL_IO.DO_Water_Valve_35_Close := TRUE;
GVL_IO.DO_Water_Valve_36_Open := FALSE;
GVL_IO.DO_Water_Valve_36_Close := TRUE;

FOR L_i := 1 TO 6 DO
    GVL_IO.DO_Water_Local_Valve_Open[L_i] := FALSE;
    GVL_IO.DO_Water_Local_Valve_Close[L_i] := TRUE;
END_FOR;

GVL_IO.DO_Gas_Valve_Close := TRUE;

GVL_IO.DO_Gas_Siren :=
    GVL_IO_WRITE_RUNTIME_BUFFER.B_Gas_Fire_Siren_Enable
    AND GVL_IO_WRITE_RUNTIME_BUFFER.B_Gas_Siren_Authority;

GVL_IO.DO_Fire_Siren :=
    GVL_IO_WRITE_RUNTIME_BUFFER.B_Gas_Fire_Siren_Enable
    AND GVL_IO_WRITE_RUNTIME_BUFFER.B_Fire_Siren_Authority;

GVL_IO.DO_Security_Siren :=
    GVL_ALARM.G_Security_Siren
    OR (GVL_ALARM.G_Global_Siren AND GVL_ALARM.G_Security_Alarm);

IF GVL_IO_WRITE_RUNTIME_BUFFER.B_Distributed_Publication_Block
   AND NOT L_Prev_Distributed_Publication_Block THEN
    fbTrace(
        iLayer := TRACE_IO,
        iSource := SRC_IO,
        iReason := REASON_SAFETY_BLOCK,
        iValueBool := TRUE,
        iValueReal := UDINT_TO_REAL(GVL_DISTRIBUTED_COMMIT.Distributed_Commit_Last_Error_Code),
        iText := 'IO blocked by distributed publication continuity authority'
    );
END_IF;

IF GVL_IO_WRITE_RUNTIME_BUFFER.B_Output_Publication_Block
   AND NOT L_Prev_Output_Publication_Block THEN
    fbTrace(
        iLayer := TRACE_IO,
        iSource := SRC_IO,
        iReason := REASON_SAFETY_BLOCK,
        iValueBool := TRUE,
        iValueReal := UDINT_TO_REAL(GVL_OUTPUT_EPOCH.Output_Last_Error_Code),
        iText := 'IO blocked by finalized output publication authority'
    );
END_IF;

L_Prev_Distributed_Publication_Block := GVL_IO_WRITE_RUNTIME_BUFFER.B_Distributed_Publication_Block;
L_Prev_Output_Publication_Block := GVL_IO_WRITE_RUNTIME_BUFFER.B_Output_Publication_Block;

// >>> BULK_SYNC_ANCHOR: PRG_IO_Write_Phase_02_Hard_Stop_Safe_State <<<
END_PROGRAM