PROGRAM PRG_HMI_Access_Dashboard

GVL_HMI_ACCESS.G_Safety_Mode := GVL_SAFETY_SHUTDOWN.G_Safety_Mode;
GVL_HMI_ACCESS.G_User_Access_Level := GVL_INTENT_USER.I_User_Access_Level;
GVL_HMI_ACCESS.G_Manual_Access_OK :=
    GVL_INTENT_USER.I_Source_Valid AND (GVL_INTENT_USER.I_User_Access_Level >= 2);

GVL_HMI_ACCESS.G_Runtime_Required := GVL_ACCESS_RUNTIME.G_Runtime_Required;
GVL_HMI_ACCESS.G_Runtime_Executed := GVL_ACCESS_RUNTIME.G_Runtime_Executed;
GVL_HMI_ACCESS.G_Runtime_Idle_By_Design := GVL_ACCESS_RUNTIME.G_Runtime_Idle_By_Design;
GVL_HMI_ACCESS.G_Runtime_Blocked_By_Distributed_Gates := GVL_ACCESS_RUNTIME.G_Runtime_Blocked_By_Distributed_Gates;
GVL_HMI_ACCESS.G_Any_Pulse_Active := GVL_ACCESS_RUNTIME.G_Any_Pulse_Active;
GVL_HMI_ACCESS.G_Last_Update_MS := GVL_ACCESS_RUNTIME.G_Last_Update_MS;
GVL_HMI_ACCESS.G_Status_Code := GVL_ACCESS_RUNTIME.G_Status_Code;
GVL_HMI_ACCESS.G_Status_Text := GVL_ACCESS_RUNTIME.G_Status_Text;

GVL_HMI_ACCESS.G_Command_Lock_1_Open := GVL_COMMAND_SHADOW.G_Lock_1_Open;
GVL_HMI_ACCESS.G_Command_Lock_1_Close := GVL_COMMAND_SHADOW.G_Lock_1_Close;
GVL_HMI_ACCESS.G_Command_Lock_2_Open := GVL_COMMAND_SHADOW.G_Lock_2_Open;
GVL_HMI_ACCESS.G_Command_Lock_2_Close := GVL_COMMAND_SHADOW.G_Lock_2_Close;
GVL_HMI_ACCESS.G_Command_Gate_Open := GVL_COMMAND_SHADOW.G_Gate_Open;
GVL_HMI_ACCESS.G_Command_Wicket_Open := GVL_COMMAND_SHADOW.G_Wicket_Open;

GVL_HMI_ACCESS.G_Output_Lock_1_Open := GVL_ACCESS_OUTPUT.DO_Lock_1_Open;
GVL_HMI_ACCESS.G_Output_Lock_1_Close := GVL_ACCESS_OUTPUT.DO_Lock_1_Close;
GVL_HMI_ACCESS.G_Output_Lock_2_Open := GVL_ACCESS_OUTPUT.DO_Lock_2_Open;
GVL_HMI_ACCESS.G_Output_Lock_2_Close := GVL_ACCESS_OUTPUT.DO_Lock_2_Close;
GVL_HMI_ACCESS.G_Output_Gate_Open := GVL_ACCESS_OUTPUT.DO_Gate_Open;
GVL_HMI_ACCESS.G_Output_Wicket_Open := GVL_ACCESS_OUTPUT.DO_Wicket_Open;

GVL_HMI_ACCESS.G_Physical_Lock_1_Open := GVL_IO.DO_Lock_1_Open;
GVL_HMI_ACCESS.G_Physical_Lock_1_Close := GVL_IO.DO_Lock_1_Close;
GVL_HMI_ACCESS.G_Physical_Lock_2_Open := GVL_IO.DO_Lock_2_Open;
GVL_HMI_ACCESS.G_Physical_Lock_2_Close := GVL_IO.DO_Lock_2_Close;
GVL_HMI_ACCESS.G_Physical_Gate_Open := GVL_IO.DO_Gate_Open;
GVL_HMI_ACCESS.G_Physical_Wicket_Open := GVL_IO.DO_Wicket_Open;

GVL_HMI_ACCESS.G_Fire_Evacuation_Access_Active := GVL_SAFETY_SHUTDOWN.G_Safety_Mode = FIRE;
GVL_HMI_ACCESS.G_Gas_Access_Release_Active := GVL_SAFETY_SHUTDOWN.G_Safety_Mode = GAS;
GVL_HMI_ACCESS.G_Safety_Cleared_Active :=
    (GVL_SAFETY_SHUTDOWN.G_Safety_Mode = WATER_LEAK)
    OR (GVL_SAFETY_SHUTDOWN.G_Safety_Mode = GLOBAL_STOP);
GVL_HMI_ACCESS.G_Distributed_Block_Active := GVL_ACCESS_RUNTIME.G_Runtime_Blocked_By_Distributed_Gates;

IF GVL_HMI_ACCESS.G_Fire_Evacuation_Access_Active THEN
    GVL_HMI_ACCESS.G_Reason_Text := 'Fire evacuation access active';
ELSIF GVL_HMI_ACCESS.G_Gas_Access_Release_Active THEN
    GVL_HMI_ACCESS.G_Reason_Text := 'Gas access release active';
ELSIF GVL_HMI_ACCESS.G_Safety_Cleared_Active THEN
    GVL_HMI_ACCESS.G_Reason_Text := 'Access outputs cleared by safety mode';
ELSIF GVL_HMI_ACCESS.G_Distributed_Block_Active THEN
    GVL_HMI_ACCESS.G_Reason_Text := 'Access blocked by distributed gates';
ELSIF GVL_HMI_ACCESS.G_Any_Pulse_Active THEN
    GVL_HMI_ACCESS.G_Reason_Text := 'Access pulse active';
ELSIF GVL_HMI_ACCESS.G_Manual_Access_OK THEN
    GVL_HMI_ACCESS.G_Reason_Text := 'Manual access allowed';
ELSE
    GVL_HMI_ACCESS.G_Reason_Text := 'Access idle or manual access denied';
END_IF;

// >>> BULK_SYNC_ANCHOR: PRG_HMI_Access_Dashboard <<<
END_PROGRAM
