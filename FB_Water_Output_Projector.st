FUNCTION_BLOCK FB_Water_Output_Projector
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
END_VAR
VAR
    L_i : INT;

    L_Authority : ST_Water_Isolation_Authority_State;
    L_Valve : ST_Water_Valve_Runtime_State;
    L_Output : ST_Water_Output_Projection_State;

    L_Any_Projected : BOOL;
    L_Any_Denied : BOOL;
    L_Global_Fallback : BOOL;
END_VAR

// Deterministic authority -> output projection.
// No direct semantic logic.
// No topology decisions.
// No diagnostics ownership.

IF NOT VI_Enable THEN
    GVL_Water_Output_Projection.G_Runtime_Valid := FALSE;
    RETURN;
END_IF;

L_Any_Projected := FALSE;
L_Any_Denied := FALSE;
L_Global_Fallback := FALSE;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_FLOOD_SENSORS DO

    L_Authority :=
        GVL_Water_Isolation_Authority.G_Authority_State[L_i];

    L_Valve :=
        GVL_Water_Valve_Runtime.G_Valve_Runtime_State[L_i];

    L_Output := (Projection_Valid := FALSE);

    L_Output.Projection_Valid := TRUE;
    L_Output.Projection_System_Time_MS := VI_System_Time_MS;

    L_Output.Output_Owner_Valid := TRUE;
    L_Output.Output_Owner_Id := TO_UINT(L_i);

    L_Output.Valve_Id := L_Valve.Valve_Id;
    L_Output.Valve_Group_Id := L_Valve.Valve_Group_Id;

    L_Output.Selective_Authority_Allowed :=
        L_Authority.Selective_Authority_Allowed;

    L_Output.Global_Fallback_Required :=
        L_Authority.Global_Fallback_Required;

    L_Output.Authority_Valid :=
        L_Authority.Decision_Valid;

    IF L_Output.Global_Fallback_Required THEN
        L_Output.Projection_Allowed := TRUE;
        L_Output.Physical_Close_Project := TRUE;
        L_Output.Expected_Closed := TRUE;
        L_Output.Projection_Code := 1;
        L_Output.Projection_Text := 'Global fallback output projection active';
        L_Global_Fallback := TRUE;

    ELSIF L_Output.Selective_Authority_Allowed AND L_Output.Authority_Valid THEN
        L_Output.Projection_Allowed := TRUE;
        L_Output.Physical_Close_Project := TRUE;
        L_Output.Expected_Closed := TRUE;
        L_Output.Projection_Code := 10;
        L_Output.Projection_Text := 'Selective authority output projection active';

    ELSE
        L_Output.Projection_Denied := TRUE;
        L_Output.Projection_Code := 100;
        L_Output.Projection_Text := 'Projection denied: authority unavailable';
        L_Any_Denied := TRUE;
    END_IF;

    L_Output.Confirmed_Closed := L_Valve.Confirmed_Closed;
    L_Output.Confirmed_Open := L_Valve.Confirmed_Open;
    L_Output.Confirmation_Unknown := L_Valve.Confirmation_Unknown;

    L_Output.Projection_Activated_Event := L_Output.Projection_Allowed;
    L_Output.Projection_Denied_Event := L_Output.Projection_Denied;

    GVL_Water_Output_Projection.G_Output_Projection_State[L_i] := L_Output;

    L_Any_Projected := L_Any_Projected OR L_Output.Projection_Allowed;
END_FOR;

GVL_Water_Output_Projection.G_Any_Output_Projected := L_Any_Projected;
GVL_Water_Output_Projection.G_Any_Projection_Denied := L_Any_Denied;
GVL_Water_Output_Projection.G_Global_Fallback_Projecting := L_Global_Fallback;
GVL_Water_Output_Projection.G_Runtime_Valid := TRUE;
GVL_Water_Output_Projection.G_Last_Update_MS := VI_System_Time_MS;

IF L_Global_Fallback THEN
    GVL_Water_Output_Projection.G_Status_Code := 2;
    GVL_Water_Output_Projection.G_Status_Text := 'Global fallback output projection active';
ELSIF L_Any_Projected THEN
    GVL_Water_Output_Projection.G_Status_Code := 1;
    GVL_Water_Output_Projection.G_Status_Text := 'Selective output projection active';
ELSE
    GVL_Water_Output_Projection.G_Status_Code := 0;
    GVL_Water_Output_Projection.G_Status_Text := 'No output projections active';
END_IF;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Water_Output_Projector <<<
