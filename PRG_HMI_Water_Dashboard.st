PROGRAM PRG_HMI_Water_Dashboard
VAR
    L_i : INT;
END_VAR

FOR L_i := 1 TO 4 DO
    GVL_HMI.G_HMI_Water_Emergency_Open_Active[L_i] := GVL_WATER_EMERGENCY_OPEN.G_Open_Active[L_i];
    GVL_HMI.G_HMI_Water_Emergency_Open_Remaining_MS[L_i] := GVL_WATER_EMERGENCY_OPEN.G_Open_Remaining_MS[L_i];
    GVL_HMI.G_HMI_Water_Emergency_Open_Count_Today[L_i] := GVL_WATER_EMERGENCY_OPEN.G_Open_Count_Today[L_i];
END_FOR;

GVL_HMI.G_HMI_Water_Emergency_Open_Any_Active := GVL_WATER_EMERGENCY_OPEN.G_Any_Open_Active;
GVL_HMI.G_HMI_Water_Emergency_Open_Last_Accepted := GVL_WATER_EMERGENCY_OPEN.G_Last_Request_Accepted;
GVL_HMI.G_HMI_Water_Emergency_Open_Last_Denied := GVL_WATER_EMERGENCY_OPEN.G_Last_Request_Denied;
GVL_HMI.G_HMI_Water_Emergency_Open_Last_Denial_Code := GVL_WATER_EMERGENCY_OPEN.G_Last_Denial_Code;
GVL_HMI.G_HMI_Water_Emergency_Open_Last_Event_Group := GVL_WATER_EMERGENCY_OPEN.G_Last_Event_Group;
GVL_HMI.G_HMI_Water_Emergency_Open_Last_Event_MS := GVL_WATER_EMERGENCY_OPEN.G_Last_Event_MS;
GVL_HMI.G_HMI_Water_Emergency_Open_Status_Text := GVL_WATER_EMERGENCY_OPEN.G_Status_Text;

IF GVL_WATER_EMERGENCY_OPEN.G_Last_Request_Denied THEN
    GVL_HMI.G_HMI_Water_Emergency_Open_Status_Level := 2;
ELSIF GVL_WATER_EMERGENCY_OPEN.G_Any_Open_Active THEN
    GVL_HMI.G_HMI_Water_Emergency_Open_Status_Level := 1;
ELSE
    GVL_HMI.G_HMI_Water_Emergency_Open_Status_Level := 0;
END_IF;

// >>> BULK_SYNC_ANCHOR: PRG_HMI_Water_Dashboard <<<
END_PROGRAM
