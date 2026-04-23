PROGRAM PRG_Command_Verifier
VAR
    L_Mismatch_Count : INT := 0;
END_VAR

L_Mismatch_Count := 0;

IF GVL_COMMAND.G_Gas_Valve_Close <> GVL_COMMAND_SHADOW.G_Gas_Valve_Close THEN
    L_Mismatch_Count := L_Mismatch_Count + 1;
END_IF;

IF GVL_COMMAND.G_Boiler_Stop <> GVL_COMMAND_SHADOW.G_Boiler_Stop THEN
    L_Mismatch_Count := L_Mismatch_Count + 1;
END_IF;

IF GVL_COMMAND.G_Vent_Stop <> GVL_COMMAND_SHADOW.G_Vent_Stop THEN
    L_Mismatch_Count := L_Mismatch_Count + 1;
END_IF;

IF GVL_COMMAND.G_Supply_100_Req <> GVL_COMMAND_SHADOW.G_Supply_100_Req THEN
    L_Mismatch_Count := L_Mismatch_Count + 1;
END_IF;

IF GVL_COMMAND.G_Supply_80_Req <> GVL_COMMAND_SHADOW.G_Supply_80_Req THEN
    L_Mismatch_Count := L_Mismatch_Count + 1;
END_IF;

IF GVL_COMMAND.G_Vent_PV3_Boost <> GVL_COMMAND_SHADOW.G_Vent_PV3_Boost THEN
    L_Mismatch_Count := L_Mismatch_Count + 1;
END_IF;

IF GVL_COMMAND.G_Close_Valve_35 <> GVL_COMMAND_SHADOW.G_Close_Valve_35 THEN
    L_Mismatch_Count := L_Mismatch_Count + 1;
END_IF;

IF GVL_COMMAND.G_Close_Valve_36 <> GVL_COMMAND_SHADOW.G_Close_Valve_36 THEN
    L_Mismatch_Count := L_Mismatch_Count + 1;
END_IF;

IF GVL_COMMAND.G_Lock_1_Open <> GVL_COMMAND_SHADOW.G_Lock_1_Open THEN
    L_Mismatch_Count := L_Mismatch_Count + 1;
END_IF;

IF GVL_COMMAND.G_Lock_1_Close <> GVL_COMMAND_SHADOW.G_Lock_1_Close THEN
    L_Mismatch_Count := L_Mismatch_Count + 1;
END_IF;

IF GVL_COMMAND.G_Lock_2_Open <> GVL_COMMAND_SHADOW.G_Lock_2_Open THEN
    L_Mismatch_Count := L_Mismatch_Count + 1;
END_IF;

IF GVL_COMMAND.G_Lock_2_Close <> GVL_COMMAND_SHADOW.G_Lock_2_Close THEN
    L_Mismatch_Count := L_Mismatch_Count + 1;
END_IF;

// NEW: gate/wicket verification
IF GVL_COMMAND.G_Gate_Open <> GVL_COMMAND_SHADOW.G_Gate_Open THEN
    L_Mismatch_Count := L_Mismatch_Count + 1;
END_IF;

IF GVL_COMMAND.G_Wicket_Open <> GVL_COMMAND_SHADOW.G_Wicket_Open THEN
    L_Mismatch_Count := L_Mismatch_Count + 1;
END_IF;

GVL_COMMAND_VERIFY.Command_Mismatch_Count := L_Mismatch_Count;
GVL_COMMAND_VERIFY.Command_Match_OK := (L_Mismatch_Count = 0);

IF L_Mismatch_Count > 0 THEN
    GVL_COMMAND_VERIFY.Command_Mismatch_Active := TRUE;
END_IF;