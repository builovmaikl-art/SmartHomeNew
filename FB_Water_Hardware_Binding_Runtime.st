FUNCTION_BLOCK FB_Water_Hardware_Binding_Runtime
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
END_VAR
VAR
    L_i : INT;
    L_Channel : UINT;
    L_Binding : ST_IO_Binding_Record;
    L_Any_Invalid : BOOL;
    L_Any_Missing : BOOL;
END_VAR

IF NOT VI_Enable THEN
    GVL_IO_Binding_Runtime.G_Runtime_Valid := FALSE;
    RETURN;
END_IF;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_FLOOD_SENSORS DO

    // Flood sensor runtime binding.
    L_Binding :=
        GVL_IO_Binding_Config.G_Flood_Sensor_Binding[L_i];

    IF L_Binding.Binding_Valid THEN

        L_Channel := L_Binding.Physical_Channel_Id;

        IF (L_Channel >= 1)
           AND (L_Channel <= GVL_CONSTANTS.C_MAX_FLOOD_SENSORS) THEN

            GVL_IO_Binding_Runtime.G_Flood_Sensor_Value[L_i] :=
                GVL_IO.DI_Flood_Sensors[L_Channel];

            GVL_IO_Binding_Runtime.G_Flood_Sensor_Valid[L_i] := TRUE;

        ELSE

            L_Any_Invalid := TRUE;

        END_IF;

    ELSE

        L_Any_Missing := TRUE;

    END_IF;

    // Valve close feedback runtime binding.
    L_Binding :=
        GVL_IO_Binding_Config.G_Water_Valve_Close_FB_Binding[L_i];

    IF L_Binding.Binding_Valid THEN

        L_Channel := L_Binding.Physical_Channel_Id;

        IF (L_Channel >= 1)
           AND (L_Channel <= GVL_CONSTANTS.C_MAX_WATER_ZONES) THEN

            GVL_IO_Binding_Runtime.G_Water_Valve_Close_FB_Value[L_i] :=
                GVL_IO.DI_Water_Zone_Close_FB[L_Channel];

            GVL_IO_Binding_Runtime.G_Water_Valve_Close_FB_Valid[L_i] := TRUE;

        ELSE

            L_Any_Invalid := TRUE;

        END_IF;

    END_IF;

    // Valve open feedback runtime binding.
    L_Binding :=
        GVL_IO_Binding_Config.G_Water_Valve_Open_FB_Binding[L_i];

    IF L_Binding.Binding_Valid THEN

        L_Channel := L_Binding.Physical_Channel_Id;

        IF (L_Channel >= 1)
           AND (L_Channel <= GVL_CONSTANTS.C_MAX_WATER_ZONES) THEN

            GVL_IO_Binding_Runtime.G_Water_Valve_Open_FB_Value[L_i] :=
                GVL_IO.DI_Water_Zone_Open_FB[L_Channel];

            GVL_IO_Binding_Runtime.G_Water_Valve_Open_FB_Valid[L_i] := TRUE;

        ELSE

            L_Any_Invalid := TRUE;

        END_IF;

    END_IF;

END_FOR;

GVL_IO_Binding_Runtime.G_Any_Invalid_Binding :=
    L_Any_Invalid;

GVL_IO_Binding_Runtime.G_Any_Missing_Binding :=
    L_Any_Missing;

GVL_IO_Binding_Runtime.G_Runtime_Valid := TRUE;
GVL_IO_Binding_Runtime.G_Last_Update_MS := VI_System_Time_MS;

IF L_Any_Invalid THEN
    GVL_IO_Binding_Runtime.G_Status_Code := 2;
    GVL_IO_Binding_Runtime.G_Status_Text :=
        'Hardware binding invalid';
ELSIF L_Any_Missing THEN
    GVL_IO_Binding_Runtime.G_Status_Code := 1;
    GVL_IO_Binding_Runtime.G_Status_Text :=
        'Hardware binding incomplete';
ELSE
    GVL_IO_Binding_Runtime.G_Status_Code := 0;
    GVL_IO_Binding_Runtime.G_Status_Text :=
        'Hardware binding runtime healthy';
END_IF;

END_FUNCTION_BLOCK