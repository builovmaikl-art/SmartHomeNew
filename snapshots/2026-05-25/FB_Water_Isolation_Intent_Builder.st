FUNCTION_BLOCK FB_Water_Isolation_Intent_Builder
VAR_INPUT
    VI_Enable : BOOL;
END_VAR
VAR
    L_i : INT;
    L_State : ST_Water_Isolation_Runtime_State;
    L_Any_Selective : BOOL;
    L_Global_Fallback : BOOL;
END_VAR

IF NOT VI_Enable THEN
    GVL_Water_Isolation_Intent.G_Intent_Valid := FALSE;
    RETURN;
END_IF;

L_Any_Selective := FALSE;
L_Global_Fallback := FALSE;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_FLOOD_SENSORS DO

    L_State := GVL_Water_Isolation_Runtime.G_Isolation_Runtime_State[L_i];

    GVL_Water_Isolation_Intent.G_Zone_Close_Requested[L_i] := FALSE;
    GVL_Water_Isolation_Intent.G_Valve_Group_Close_Requested[L_i] := FALSE;

    IF L_State.Selective_Isolation_Requested THEN

        IF (L_State.Hydraulic_Zone_Id >= 1)
           AND (L_State.Hydraulic_Zone_Id <= GVL_CONSTANTS.C_MAX_FLOOD_SENSORS) THEN

            GVL_Water_Isolation_Intent.G_Zone_Close_Requested[
                L_State.Hydraulic_Zone_Id
            ] := TRUE;

        END_IF;

        IF (L_State.Valve_Group_Id >= 1)
           AND (L_State.Valve_Group_Id <= GVL_CONSTANTS.C_MAX_FLOOD_SENSORS) THEN

            GVL_Water_Isolation_Intent.G_Valve_Group_Close_Requested[
                L_State.Valve_Group_Id
            ] := TRUE;

        END_IF;

        L_Any_Selective := TRUE;

    END_IF;

    IF L_State.Global_Isolation_Requested THEN
        L_Global_Fallback := TRUE;
    END_IF;

END_FOR;

GVL_Water_Isolation_Intent.G_Global_Isolation_Requested :=
    L_Global_Fallback;

GVL_Water_Isolation_Intent.G_Intent_Valid := TRUE;

IF L_Global_Fallback THEN
    GVL_Water_Isolation_Intent.G_Status_Code := 2;
    GVL_Water_Isolation_Intent.G_Status_Text :=
        'Global isolation fallback requested';
ELSIF L_Any_Selective THEN
    GVL_Water_Isolation_Intent.G_Status_Code := 1;
    GVL_Water_Isolation_Intent.G_Status_Text :=
        'Localized isolation intent available';
ELSE
    GVL_Water_Isolation_Intent.G_Status_Code := 0;
    GVL_Water_Isolation_Intent.G_Status_Text :=
        'No isolation intent active';
END_IF;

END_FUNCTION_BLOCK