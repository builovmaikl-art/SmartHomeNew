PROGRAM PRG_IO_Write_Phase_04_Alarm_Trace
// IO write phase 04: publish final sirens, gas valve and normal trace.
VAR
    fbTrace : FB_Trace_Write;
END_VAR

GVL_IO.DO_Gas_Siren :=
    GVL_IO_WRITE_RUNTIME_BUFFER.B_Gas_Fire_Siren_Enable
    AND GVL_IO_WRITE_RUNTIME_BUFFER.B_Gas_Siren_Authority;

GVL_IO.DO_Fire_Siren :=
    GVL_IO_WRITE_RUNTIME_BUFFER.B_Gas_Fire_Siren_Enable
    AND GVL_IO_WRITE_RUNTIME_BUFFER.B_Fire_Siren_Authority;

GVL_IO.DO_Security_Siren :=
    GVL_ALARM.G_Security_Siren
    OR (GVL_ALARM.G_Global_Siren AND GVL_ALARM.G_Security_Alarm);

GVL_IO.DO_Gas_Valve_Close := GVL_COMMAND_SHADOW.G_Gas_Valve_Close;

fbTrace(
    iLayer := TRACE_IO,
    iSource := SRC_IO,
    iReason := REASON_DOMAIN_PROJECTION,
    iValueBool := TRUE,
    iValueReal := 0.0,
    iText := 'IO write projection executed'
);

// >>> BULK_SYNC_ANCHOR: PRG_IO_Write_Phase_04_Alarm_Trace <<<
END_PROGRAM
