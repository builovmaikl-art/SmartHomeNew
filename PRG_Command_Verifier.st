PROGRAM PRG_Command_Verifier
VAR
    L_Mismatch_Count : INT := 0;
    L_Runtime_Error : BOOL := FALSE;
    L_Now_MS : UDINT;
    fbLog : FB_LogEvent;
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;

// ===============================
// 1. COMMAND MISMATCH CHECK
// ===============================
L_Mismatch_Count := 0;

IF GVL_COMMAND.G_Gas_Valve_Close <> GVL_COMMAND_SHADOW.G_Gas_Valve_Close THEN L_Mismatch_Count := L_Mismatch_Count + 1; END_IF;
IF GVL_COMMAND.G_Boiler_Stop <> GVL_COMMAND_SHADOW.G_Boiler_Stop THEN L_Mismatch_Count := L_Mismatch_Count + 1; END_IF;
IF GVL_COMMAND.G_Vent_Stop <> GVL_COMMAND_SHADOW.G_Vent_Stop THEN L_Mismatch_Count := L_Mismatch_Count + 1; END_IF;
IF GVL_COMMAND.G_Supply_100_Req <> GVL_COMMAND_SHADOW.G_Supply_100_Req THEN L_Mismatch_Count := L_Mismatch_Count + 1; END_IF;
IF GVL_COMMAND.G_Supply_80_Req <> GVL_COMMAND_SHADOW.G_Supply_80_Req THEN L_Mismatch_Count := L_Mismatch_Count + 1; END_IF;
IF GVL_COMMAND.G_Vent_PV3_Boost <> GVL_COMMAND_SHADOW.G_Vent_PV3_Boost THEN L_Mismatch_Count := L_Mismatch_Count + 1; END_IF;
IF GVL_COMMAND.G_Close_Valve_35 <> GVL_COMMAND_SHADOW.G_Close_Valve_35 THEN L_Mismatch_Count := L_Mismatch_Count + 1; END_IF;
IF GVL_COMMAND.G_Close_Valve_36 <> GVL_COMMAND_SHADOW.G_Close_Valve_36 THEN L_Mismatch_Count := L_Mismatch_Count + 1; END_IF;
IF GVL_COMMAND.G_Lock_1_Open <> GVL_COMMAND_SHADOW.G_Lock_1_Open THEN L_Mismatch_Count := L_Mismatch_Count + 1; END_IF;
IF GVL_COMMAND.G_Lock_1_Close <> GVL_COMMAND_SHADOW.G_Lock_1_Close THEN L_Mismatch_Count := L_Mismatch_Count + 1; END_IF;
IF GVL_COMMAND.G_Lock_2_Open <> GVL_COMMAND_SHADOW.G_Lock_2_Open THEN L_Mismatch_Count := L_Mismatch_Count + 1; END_IF;
IF GVL_COMMAND.G_Lock_2_Close <> GVL_COMMAND_SHADOW.G_Lock_2_Close THEN L_Mismatch_Count := L_Mismatch_Count + 1; END_IF;
IF GVL_COMMAND.G_Gate_Open <> GVL_COMMAND_SHADOW.G_Gate_Open THEN L_Mismatch_Count := L_Mismatch_Count + 1; END_IF;
IF GVL_COMMAND.G_Wicket_Open <> GVL_COMMAND_SHADOW.G_Wicket_Open THEN L_Mismatch_Count := L_Mismatch_Count + 1; END_IF;

GVL_COMMAND_VERIFY.Command_Mismatch_Count := L_Mismatch_Count;
GVL_COMMAND_VERIFY.Command_Match_OK := (L_Mismatch_Count = 0);
GVL_COMMAND_VERIFY.Command_Mismatch_Active := (L_Mismatch_Count > 0);

// ===============================
// 2. RUNTIME SANITY CHECKS
// ===============================
L_Runtime_Error := FALSE;

// Example: GAS but valve not closed
IF (GVL_SAFETY_SHUTDOWN.G_Safety_Mode = GAS) AND (NOT GVL_IO.DO_Gas_Valve_Close) THEN
    L_Runtime_Error := TRUE;
    GVL_COMMAND_VERIFY.Runtime_Last_Error_Code := 1;
    GVL_COMMAND_VERIFY.Runtime_Last_Error_Text := 'Gas valve not closed';
END_IF;

// Example: FIRE but no exhaust
IF (GVL_SAFETY_SHUTDOWN.G_Safety_Mode = FIRE) AND (GVL_IO.AO_Exhaust_Fans[1] = 0) THEN
    L_Runtime_Error := TRUE;
    GVL_COMMAND_VERIFY.Runtime_Last_Error_Code := 2;
    GVL_COMMAND_VERIFY.Runtime_Last_Error_Text := 'Smoke exhaust not active';
END_IF;

// Apply result
IF L_Runtime_Error THEN
    GVL_COMMAND_VERIFY.Runtime_Sanity_OK := FALSE;
    GVL_COMMAND_VERIFY.Runtime_Sanity_Error_Count := GVL_COMMAND_VERIFY.Runtime_Sanity_Error_Count + 1;
    GVL_COMMAND_VERIFY.Runtime_Last_Error_Time_MS := L_Now_MS;

    // Log event (edge-like behavior via counter change)
    fbLog(
        VI_Event_Type := 1001,
        VI_Timestamp := L_Now_MS,
        VI_Param1 := GVL_COMMAND_VERIFY.Runtime_Last_Error_Code,
        VI_Param2 := GVL_COMMAND_VERIFY.Runtime_Sanity_Error_Count
    );
ELSE
    GVL_COMMAND_VERIFY.Runtime_Sanity_OK := TRUE;
END_IF;

END_PROGRAM
