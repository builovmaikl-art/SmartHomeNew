PROGRAM PRG_Command_Arbitration
VAR
    L_Mode : E_Safety_Mode;
    L_Safety_Active : BOOL;
    L_User_Access_OK : BOOL;
    L_i : INT;

    // FULL deterministic buffer (all active shadow fields)
    L_Gas_Valve_Close : BOOL;
    L_Boiler_Stop : BOOL;
    L_Supply_100_Req : BOOL;
    L_Supply_80_Req : BOOL;
    L_Vent_PV3_Boost : BOOL;
    L_Exhaust_100_Req : BOOL;
    L_Vent_Stop : BOOL;
    L_Vent_Block : BOOL;

    L_Heating_Block : BOOL;
    L_Heating_Emergency_Stop : BOOL;
    L_Heating_Gas_Safety_Stop : BOOL;

    L_Water_Block : BOOL;
    L_Water_Emergency_Stop : BOOL;
    L_Close_Valve_35 : BOOL;
    L_Close_Valve_36 : BOOL;

    L_Lock_1_Open : BOOL;
    L_Lock_1_Close : BOOL;
    L_Lock_2_Open : BOOL;
    L_Lock_2_Close : BOOL;
    L_Gate_Open : BOOL;
    L_Wicket_Open : BOOL;
END_VAR

// === PRIORITY 1: ROLE CONFLICT ===
IF GVL_STATUS.G_Is_Active_PLC AND GVL_STATUS.G_Other_PLC_Is_Active THEN
    GVL_HEALTH_BRIDGE.G_Role_Conflict_Error := TRUE;

    GVL_COMMAND_SHADOW.G_Gas_Valve_Close := TRUE;
    GVL_COMMAND_SHADOW.G_Boiler_Stop := TRUE;
    GVL_COMMAND_SHADOW.G_Vent_Stop := TRUE;
    GVL_COMMAND_SHADOW.G_Vent_Block := TRUE;
    GVL_COMMAND_SHADOW.G_Heating_Block := TRUE;
    GVL_COMMAND_SHADOW.G_Heating_Emergency_Stop := TRUE;
    GVL_COMMAND_SHADOW.G_Heating_Gas_Safety_Stop := TRUE;
    GVL_COMMAND_SHADOW.G_Water_Block := TRUE;
    GVL_COMMAND_SHADOW.G_Water_Emergency_Stop := TRUE;
    GVL_COMMAND_SHADOW.G_Close_Valve_35 := TRUE;
    GVL_COMMAND_SHADOW.G_Close_Valve_36 := TRUE;

    GVL_COMMAND_SHADOW.G_Lock_1_Open := FALSE;
    GVL_COMMAND_SHADOW.G_Lock_1_Close := FALSE;
    GVL_COMMAND_SHADOW.G_Lock_2_Open := FALSE;
    GVL_COMMAND_SHADOW.G_Lock_2_Close := FALSE;
    GVL_COMMAND_SHADOW.G_Gate_Open := FALSE;
    GVL_COMMAND_SHADOW.G_Wicket_Open := FALSE;
    RETURN;
END_IF;

// === PRIORITY 2: PLC INACTIVE ===
IF NOT GVL_STATUS.G_Is_Active_PLC THEN
    GVL_COMMAND_SHADOW.G_Gas_Valve_Close := GVL_COMMAND_POLICY_CONFIG.G_PLC_Inactive_Close_Gas;
    GVL_COMMAND_SHADOW.G_Boiler_Stop := GVL_COMMAND_POLICY_CONFIG.G_PLC_Inactive_Stop_Boiler;
    GVL_COMMAND_SHADOW.G_Heating_Block := GVL_COMMAND_POLICY_CONFIG.G_PLC_Inactive_Block_Heating;
    GVL_COMMAND_SHADOW.G_Vent_Stop := GVL_COMMAND_POLICY_CONFIG.G_PLC_Inactive_Stop_Vent;
    GVL_COMMAND_SHADOW.G_Water_Block := GVL_COMMAND_POLICY_CONFIG.G_PLC_Inactive_Block_Water;

    GVL_COMMAND_SHADOW.G_Vent_Block := FALSE;
    GVL_COMMAND_SHADOW.G_Heating_Emergency_Stop := FALSE;
    GVL_COMMAND_SHADOW.G_Heating_Gas_Safety_Stop := FALSE;
    GVL_COMMAND_SHADOW.G_Water_Emergency_Stop := FALSE;
    GVL_COMMAND_SHADOW.G_Close_Valve_35 := FALSE;
    GVL_COMMAND_SHADOW.G_Close_Valve_36 := FALSE;

    GVL_COMMAND_SHADOW.G_Lock_1_Open := FALSE;
    GVL_COMMAND_SHADOW.G_Lock_1_Close := FALSE;
    GVL_COMMAND_SHADOW.G_Lock_2_Open := FALSE;
    GVL_COMMAND_SHADOW.G_Lock_2_Close := FALSE;
    GVL_COMMAND_SHADOW.G_Gate_Open := FALSE;
    GVL_COMMAND_SHADOW.G_Wicket_Open := FALSE;
    RETURN;
END_IF;

// === RESET ALL ===
L_Gas_Valve_Close := FALSE;
L_Boiler_Stop := FALSE;
L_Supply_100_Req := FALSE;
L_Supply_80_Req := FALSE;
L_Vent_PV3_Boost := FALSE;
L_Exhaust_100_Req := FALSE;
L_Vent_Stop := FALSE;
L_Vent_Block := FALSE;

L_Heating_Block := FALSE;
L_Heating_Emergency_Stop := FALSE;
L_Heating_Gas_Safety_Stop := FALSE;

L_Water_Block := FALSE;
L_Water_Emergency_Stop := FALSE;
L_Close_Valve_35 := FALSE;
L_Close_Valve_36 := FALSE;

L_Lock_1_Open := FALSE;
L_Lock_1_Close := FALSE;
L_Lock_2_Open := FALSE;
L_Lock_2_Close := FALSE;
L_Gate_Open := FALSE;
L_Wicket_Open := FALSE;

// === SAFETY MODE ===
L_Mode := GVL_SAFETY_SHUTDOWN.G_Safety_Mode;
L_Safety_Active := FALSE;

CASE L_Mode OF
    FIRE:
        L_Safety_Active := TRUE;
        L_Heating_Block := TRUE;
        L_Boiler_Stop := TRUE;
        L_Vent_Stop := TRUE;
        L_Heating_Emergency_Stop := TRUE;

    GAS:
        L_Safety_Active := TRUE;
        L_Gas_Valve_Close := TRUE;
        L_Boiler_Stop := TRUE;
        L_Heating_Block := TRUE;
        L_Heating_Gas_Safety_Stop := TRUE;

    WATER_LEAK:
        L_Safety_Active := TRUE;
        L_Water_Block := TRUE;
        L_Water_Emergency_Stop := TRUE;
        L_Close_Valve_35 := TRUE;
        L_Close_Valve_36 := TRUE;

    GLOBAL_STOP:
        L_Safety_Active := TRUE;
        L_Heating_Block := TRUE;
        L_Boiler_Stop := TRUE;
        L_Vent_Stop := TRUE;
        L_Water_Block := TRUE;
        L_Water_Emergency_Stop := TRUE;
        L_Close_Valve_35 := TRUE;
        L_Close_Valve_36 := TRUE;
END_CASE;

// === FINAL WRITE ===
GVL_COMMAND_SHADOW.G_Gas_Valve_Close := L_Gas_Valve_Close;
GVL_COMMAND_SHADOW.G_Boiler_Stop := L_Boiler_Stop;
GVL_COMMAND_SHADOW.G_Supply_100_Req := L_Supply_100_Req;
GVL_COMMAND_SHADOW.G_Supply_80_Req := L_Supply_80_Req;
GVL_COMMAND_SHADOW.G_Vent_PV3_Boost := L_Vent_PV3_Boost;
GVL_COMMAND_SHADOW.G_Exhaust_100_Req := L_Exhaust_100_Req;
GVL_COMMAND_SHADOW.G_Vent_Stop := L_Vent_Stop;
GVL_COMMAND_SHADOW.G_Vent_Block := L_Vent_Block;

GVL_COMMAND_SHADOW.G_Heating_Block := L_Heating_Block;
GVL_COMMAND_SHADOW.G_Heating_Emergency_Stop := L_Heating_Emergency_Stop;
GVL_COMMAND_SHADOW.G_Heating_Gas_Safety_Stop := L_Heating_Gas_Safety_Stop;

GVL_COMMAND_SHADOW.G_Water_Block := L_Water_Block;
GVL_COMMAND_SHADOW.G_Water_Emergency_Stop := L_Water_Emergency_Stop;
GVL_COMMAND_SHADOW.G_Close_Valve_35 := L_Close_Valve_35;
GVL_COMMAND_SHADOW.G_Close_Valve_36 := L_Close_Valve_36;

GVL_COMMAND_SHADOW.G_Lock_1_Open := L_Lock_1_Open;
GVL_COMMAND_SHADOW.G_Lock_1_Close := L_Lock_1_Close;
GVL_COMMAND_SHADOW.G_Lock_2_Open := L_Lock_2_Open;
GVL_COMMAND_SHADOW.G_Lock_2_Close := L_Lock_2_Close;
GVL_COMMAND_SHADOW.G_Gate_Open := L_Gate_Open;
GVL_COMMAND_SHADOW.G_Wicket_Open := L_Wicket_Open;

END_PROGRAM
