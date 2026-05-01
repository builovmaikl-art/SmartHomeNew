PROGRAM PRG_IO_Write
VAR
    L_i : INT;
    L_Heating_Forced_Off : BOOL;
    L_Vent_Forced_Off : BOOL;
    L_Water_Forced_Off : BOOL;
    L_Access_Forced_Off : BOOL;
    fbTrace : FB_Trace_Write;
END_VAR

IF NOT GVL_STATUS.G_Is_Active_PLC THEN RETURN; END_IF;

L_Heating_Forced_Off :=
    GVL_COMMAND_SHADOW.G_Heating_Block
    OR GVL_COMMAND_SHADOW.G_Heating_Emergency_Stop
    OR GVL_COMMAND_SHADOW.G_Boiler_Stop;

L_Vent_Forced_Off :=
    GVL_COMMAND_SHADOW.G_Vent_Stop
    OR GVL_COMMAND_SHADOW.G_Vent_Block;

L_Water_Forced_Off :=
    GVL_COMMAND_SHADOW.G_Water_Block
    OR GVL_COMMAND_SHADOW.G_Water_Emergency_Stop;

L_Access_Forced_Off :=
    GVL_SAFETY_RECOVERY.G_Recovery_Active;

// HEATING
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
    IF L_i > GVL_SYSTEM_SIZE_CONFIG.G_Active_Heating_Circuits THEN
        GVL_IO.DO_Zone_Valves[L_i] := FALSE;
    ELSIF L_Heating_Forced_Off THEN
        GVL_IO.DO_Zone_Valves[L_i] := FALSE;
    ELSE
        GVL_IO.DO_Zone_Valves[L_i] := GVL_HEATING_OUTPUT.DO_Zone_Valves[L_i];
    END_IF;
END_FOR;

// WATER
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_WATER_ZONES DO
    IF L_i > GVL_SYSTEM_SIZE_CONFIG.G_Active_Water_Zones THEN
        GVL_IO.DO_Water_Zone_Enable[L_i] := FALSE;
    ELSIF L_Water_Forced_Off THEN
        GVL_IO.DO_Water_Zone_Enable[L_i] := FALSE;
    ELSE
        GVL_IO.DO_Water_Zone_Enable[L_i] := GVL_WATER_OUTPUT.DO_Water_Zone_Enable[L_i];
    END_IF;
END_FOR;

GVL_IO.DO_Gas_Valve_Close := GVL_COMMAND_SHADOW.G_Gas_Valve_Close;

fbTrace(
    iLayer := TRACE_IO,
    iSource := SRC_IO,
    iReason := REASON_DOMAIN_PROJECTION,
    iValueBool := TRUE,
    iValueReal := 0.0,
    iText := 'IO write projection executed'
);
