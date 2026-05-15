FUNCTION_BLOCK FB_Water_Isolation_Runtime_Projection
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
END_VAR
VAR
    L_i : INT;
    L_Leak_State : ST_Water_Leak_Runtime_State;
    L_Isolation_State : ST_Water_Isolation_Runtime_State;
    L_Traversal : ST_Water_Graph_Traversal_State;
    L_Any_Isolation : BOOL;
    L_Any_Selective : BOOL;
    L_Global_Fallback : BOOL;
END_VAR

IF NOT VI_Enable THEN
    GVL_Water_Isolation_Runtime.G_Runtime_Valid := FALSE;
    RETURN;
END_IF;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_FLOOD_SENSORS DO

    L_Leak_State := GVL_Water_Runtime_Projection.G_Leak_Runtime_State[L_i];
    L_Traversal := GVL_Water_Orchestration.G_Traversal_State[L_i];

    L_Isolation_State := (Projection_Valid := TRUE);
    L_Isolation_State.Projection_System_Time_MS := VI_System_Time_MS;

    L_Isolation_State.Hydraulic_Zone_Id := L_Leak_State.Hydraulic_Zone_Id;
    L_Isolation_State.Isolation_Group_Id := L_Leak_State.Isolation_Group_Id;
    L_Isolation_State.Valve_Group_Id := L_Traversal.Target_Valve_Group_Id;

    L_Isolation_State.Active_Global_Close_Path :=
        L_Leak_State.Active_Global_Close_Path;

    L_Isolation_State.Active_Safety_Latch :=
        L_Leak_State.Active_Safety_Leak_Latched;

    L_Isolation_State.Mapping_Valid :=
        L_Traversal.Traversal_Valid;

    L_Isolation_State.Fallback_To_Global_Required :=
        L_Traversal.Global_Fallback_Required;

    IF L_Leak_State.Leak_Confirmed THEN

        L_Isolation_State.Isolation_Requested := TRUE;

        IF L_Traversal.Selective_Path_Allowed
           AND NOT L_Traversal.Global_Fallback_Required THEN

            L_Isolation_State.Selective_Isolation_Requested := TRUE;
            L_Isolation_State.Reason_Code := 1;
            L_Isolation_State.Reason_Text :=
                'Selective orchestration path available';

        ELSE

            L_Isolation_State.Global_Isolation_Requested := TRUE;
            L_Isolation_State.Reason_Code := 2;
            L_Isolation_State.Reason_Text :=
                'Global fallback required';

        END_IF;

    END_IF;

    GVL_Water_Isolation_Runtime.G_Isolation_Runtime_State[L_i] :=
        L_Isolation_State;

    L_Any_Isolation :=
        L_Any_Isolation
        OR L_Isolation_State.Isolation_Requested;

    L_Any_Selective :=
        L_Any_Selective
        OR L_Isolation_State.Selective_Isolation_Requested;

    L_Global_Fallback :=
        L_Global_Fallback
        OR L_Isolation_State.Global_Isolation_Requested;

END_FOR;

GVL_Water_Isolation_Runtime.G_Any_Isolation_Requested :=
    L_Any_Isolation;

GVL_Water_Isolation_Runtime.G_Any_Selective_Isolation :=
    L_Any_Selective;

GVL_Water_Isolation_Runtime.G_Global_Fallback_Required :=
    L_Global_Fallback;

GVL_Water_Isolation_Runtime.G_Runtime_Valid := TRUE;
GVL_Water_Isolation_Runtime.G_Last_Update_MS := VI_System_Time_MS;

IF L_Global_Fallback THEN
    GVL_Water_Isolation_Runtime.G_Status_Code := 2;
    GVL_Water_Isolation_Runtime.G_Status_Text :=
        'Global isolation fallback required';
ELSIF L_Any_Selective THEN
    GVL_Water_Isolation_Runtime.G_Status_Code := 1;
    GVL_Water_Isolation_Runtime.G_Status_Text :=
        'Selective orchestration active';
ELSE
    GVL_Water_Isolation_Runtime.G_Status_Code := 0;
    GVL_Water_Isolation_Runtime.G_Status_Text :=
        'Isolation runtime active';
END_IF;

END_FUNCTION_BLOCK