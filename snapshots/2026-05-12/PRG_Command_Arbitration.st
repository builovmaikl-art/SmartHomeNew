PROGRAM PRG_Command_Arbitration
VAR
    L_Mode : E_Safety_Mode;
    L_Safety_Active : BOOL;
    L_User_Access_OK : BOOL;
    L_i : INT;

    // Local deterministic command buffer
    L_Gas_Valve_Close : BOOL;
    L_Boiler_Stop : BOOL;
    L_Supply_100_Req : BOOL;
    L_Supply_80_Req : BOOL;
    L_Vent_PV3_Boost : BOOL;
    L_Exhaust_100_Req : BOOL;
    L_Vent_Stop : BOOL;
    L_Vent_Block : BOOL;
    L_Vent_Smoke_Exhaust : BOOL;

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

// ======================================================
// PRIORITY 1: PLC ROLE VALIDATION (ABSOLUTE)
// ======================================================
IF GVL_STATUS.G_Is_Active_PLC AND GVL_STATUS.G_Other_PLC_Is_Active THEN
    GVL_HEALTH_BRIDGE.G_Role_Conflict_Error := TRUE;

    GVL_COMMAND_SHADOW.G_Gas_Valve_Close := TRUE;
    GVL_COMMAND_SHADOW.G_Boiler_Stop := TRUE;
    GVL_COMMAND_SHADOW.G_Supply_100_Req := FALSE;
    GVL_COMMAND_SHADOW.G_Supply_80_Req := FALSE;
    GVL_COMMAND_SHADOW.G_Vent_PV3_Boost := FALSE;
    GVL_COMMAND_SHADOW.G_Exhaust_100_Req := FALSE;
    GVL_COMMAND_SHADOW.G_Vent_Stop := TRUE;
    GVL_COMMAND_SHADOW.G_Vent_Block := TRUE;
    GVL_COMMAND_SHADOW.G_Vent_Smoke_Exhaust := FALSE;

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

// ======================================================
// PRIORITY 2: PLC INACTIVE
// ======================================================
IF NOT GVL_STATUS.G_Is_Active_PLC THEN
    GVL_COMMAND_SHADOW.G_Gas_Valve_Close := GVL_COMMAND_POLICY_CONFIG.G_PLC_Inactive_Close_Gas;
    GVL_COMMAND_SHADOW.G_Boiler_Stop := GVL_COMMAND_POLICY_CONFIG.G_PLC_Inactive_Stop_Boiler;
    GVL_COMMAND_SHADOW.G_Supply_100_Req := FALSE;
    GVL_COMMAND_SHADOW.G_Supply_80_Req := FALSE;
    GVL_COMMAND_SHADOW.G_Vent_PV3_Boost := FALSE;
    GVL_COMMAND_SHADOW.G_Exhaust_100_Req := FALSE;
    GVL_COMMAND_SHADOW.G_Vent_Stop := GVL_COMMAND_POLICY_CONFIG.G_PLC_Inactive_Stop_Vent;
    GVL_COMMAND_SHADOW.G_Vent_Block := FALSE;
    GVL_COMMAND_SHADOW.G_Vent_Smoke_Exhaust := FALSE;

    GVL_COMMAND_SHADOW.G_Heating_Block := GVL_COMMAND_POLICY_CONFIG.G_PLC_Inactive_Block_Heating;
    GVL_COMMAND_SHADOW.G_Heating_Emergency_Stop := FALSE;
    GVL_COMMAND_SHADOW.G_Heating_Gas_Safety_Stop := FALSE;

    GVL_COMMAND_SHADOW.G_Water_Block := GVL_COMMAND_POLICY_CONFIG.G_PLC_Inactive_Block_Water;
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

// ======================================================
// RESET LOCAL BUFFER
// ======================================================
L_Gas_Valve_Close := FALSE;
L_Boiler_Stop := FALSE;
L_Supply_100_Req := FALSE;
L_Supply_80_Req := FALSE;
L_Vent_PV3_Boost := FALSE;
L_Exhaust_100_Req := FALSE;
L_Vent_Stop := FALSE;
L_Vent_Block := FALSE;
L_Vent_Smoke_Exhaust := FALSE;

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

// ======================================================
// PRIORITY 3: SAFETY MODE
// ======================================================
L_Mode := GVL_SAFETY_SHUTDOWN.G_Safety_Mode;
L_Safety_Active := FALSE;

CASE L_Mode OF

    NORMAL:
        L_Safety_Active := FALSE;

    FIRE:
        L_Safety_Active := TRUE;
        L_Heating_Block := GVL_COMMAND_POLICY_CONFIG.G_Fire_Block_Heating;
        L_Boiler_Stop := GVL_COMMAND_POLICY_CONFIG.G_Fire_Stop_Boiler;
        L_Vent_Stop := FALSE;
        L_Vent_PV3_Boost := FALSE;
        L_Exhaust_100_Req := FALSE;
        L_Vent_Smoke_Exhaust := TRUE;
        L_Heating_Emergency_Stop := GVL_COMMAND_POLICY_CONFIG.G_Fire_Block_Heating;
        L_Lock_1_Open := GVL_COMMAND_POLICY_CONFIG.G_Fire_Open_Lock_1;
        L_Lock_2_Open := GVL_COMMAND_POLICY_CONFIG.G_Fire_Open_Lock_2;
        L_Gate_Open := GVL_COMMAND_POLICY_CONFIG.G_Fire_Open_Gate;
        L_Wicket_Open := GVL_COMMAND_POLICY_CONFIG.G_Fire_Open_Wicket;

    GAS:
        L_Safety_Active := TRUE;
        L_Gas_Valve_Close := GVL_COMMAND_POLICY_CONFIG.G_Gas_Close_Gas;
        L_Boiler_Stop := GVL_COMMAND_POLICY_CONFIG.G_Gas_Stop_Boiler;
        L_Heating_Block := GVL_COMMAND_POLICY_CONFIG.G_Gas_Block_Heating;
        L_Heating_Gas_Safety_Stop := GVL_COMMAND_POLICY_CONFIG.G_Gas_Block_Heating;
        L_Vent_PV3_Boost := TRUE;
        L_Vent_Smoke_Exhaust := FALSE;
        L_Gate_Open := GVL_COMMAND_POLICY_CONFIG.G_Gas_Open_Gate;
        L_Wicket_Open := GVL_COMMAND_POLICY_CONFIG.G_Gas_Open_Wicket;
        L_Lock_1_Open := GVL_COMMAND_POLICY_CONFIG.G_Gas_Open_Lock_1;
        L_Lock_2_Open := GVL_COMMAND_POLICY_CONFIG.G_Gas_Open_Lock_2;

    WATER_LEAK:
        L_Safety_Active := TRUE;
        L_Water_Block := GVL_COMMAND_POLICY_CONFIG.G_Water_Block_Water;
        L_Water_Emergency_Stop := GVL_COMMAND_POLICY_CONFIG.G_Water_Block_Water;
        L_Close_Valve_35 := GVL_COMMAND_POLICY_CONFIG.G_Water_Block_Water;
        L_Close_Valve_36 := GVL_COMMAND_POLICY_CONFIG.G_Water_Block_Water;

    GLOBAL_STOP:
        L_Safety_Active := TRUE;
        L_Heating_Block := GVL_COMMAND_POLICY_CONFIG.G_GlobalStop_Block_Heating;
        L_Heating_Emergency_Stop := GVL_COMMAND_POLICY_CONFIG.G_GlobalStop_Block_Heating;
        L_Boiler_Stop := GVL_COMMAND_POLICY_CONFIG.G_GlobalStop_Stop_Boiler;
        L_Vent_Stop := GVL_COMMAND_POLICY_CONFIG.G_GlobalStop_Stop_Vent;
        L_Water_Block := GVL_COMMAND_POLICY_CONFIG.G_GlobalStop_Block_Water;
        L_Water_Emergency_Stop := GVL_COMMAND_POLICY_CONFIG.G_GlobalStop_Block_Water;
        L_Close_Valve_35 := GVL_COMMAND_POLICY_CONFIG.G_GlobalStop_Block_Water;
        L_Close_Valve_36 := GVL_COMMAND_POLICY_CONFIG.G_GlobalStop_Block_Water;

ELSE
        L_Safety_Active := TRUE;
        L_Gas_Valve_Close := TRUE;
        L_Boiler_Stop := TRUE;
        L_Heating_Block := TRUE;
        L_Heating_Emergency_Stop := TRUE;
        L_Vent_Stop := TRUE;
        L_Water_Block := TRUE;
        L_Water_Emergency_Stop := TRUE;
        L_Close_Valve_35 := TRUE;
        L_Close_Valve_36 := TRUE;
END_CASE;

// ======================================================
// PRIORITY 4: USER INTENT (ONLY WHEN SAFETY IS NOT ACTIVE)
// ======================================================
L_User_Access_OK := GVL_INTENT_USER.I_Source_Valid AND (GVL_INTENT_USER.I_User_Access_Level >= 1);

IF (NOT L_Safety_Active) AND L_User_Access_OK THEN
    IF GVL_INTENT_USER.I_Lock_1_Open_Request THEN
        L_Lock_1_Open := TRUE;
        L_Lock_1_Close := FALSE;
    ELSIF GVL_INTENT_USER.I_Lock_1_Close_Request THEN
        L_Lock_1_Open := FALSE;
        L_Lock_1_Close := TRUE;
    END_IF;

    IF GVL_INTENT_USER.I_Lock_2_Open_Request THEN
        L_Lock_2_Open := TRUE;
        L_Lock_2_Close := FALSE;
    ELSIF GVL_INTENT_USER.I_Lock_2_Close_Request THEN
        L_Lock_2_Open := FALSE;
        L_Lock_2_Close := TRUE;
    END_IF;

    IF GVL_INTENT_USER.I_Gate_Open_Request THEN
        L_Gate_Open := TRUE;
    END_IF;

    IF GVL_INTENT_USER.I_Wicket_Open_Request THEN
        L_Wicket_Open := TRUE;
    END_IF;
END_IF;

// Dangerous user actions require explicit confirmation and elevated access.
IF (NOT L_Safety_Active) AND
   GVL_INTENT_USER.I_Source_Valid AND
   GVL_INTENT_USER.I_Dangerous_Action_Request AND
   GVL_INTENT_USER.I_Dangerous_Action_Confirm AND
   (GVL_INTENT_USER.I_User_Access_Level >= 2) THEN
    // Reserved for future high-risk manual actions.
    // No direct safety override is allowed here.
END_IF;

// ======================================================
// PRIORITY 5: AUTOMATION RULES (ONLY SAFE COMMAND-LEVEL ACTIONS)
// ======================================================
IF NOT L_Safety_Active THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_RULES DO
        IF GVL_STATE.G_Rule_Actions[L_i].Active AND GVL_STATE.G_Rule_Actions[L_i].Triggered THEN
            CASE GVL_STATE.G_Rule_Actions[L_i].Action_Type OF

                ACTION_SET_FLOOR_HEATING:
                    IF GVL_STATE.G_Rule_Actions[L_i].Value <= 0.0 THEN
                        L_Heating_Block := TRUE;
                        L_Boiler_Stop := TRUE;
                    END_IF;

                ACTION_SET_VENTILATION:
                    IF GVL_STATE.G_Rule_Actions[L_i].Value <= 0.0 THEN
                        L_Vent_Stop := TRUE;
                    END_IF;

            ELSE
                // Non command-level actions are handled by their own subsystem.
            END_CASE;
        END_IF;
    END_FOR;
END_IF;

// ======================================================
// POST-PROCESS CONFLICT RESOLUTION
// ======================================================
IF (L_Mode = FIRE) AND GVL_COMMAND_POLICY_CONFIG.G_Fire_Block_Lock_Close THEN
    L_Lock_1_Close := FALSE;
    L_Lock_2_Close := FALSE;
END_IF;

IF GVL_COMMAND_POLICY_CONFIG.G_Block_Close_When_Open_Commanded THEN
    IF L_Lock_1_Open AND L_Lock_1_Close THEN
        L_Lock_1_Close := FALSE;
    END_IF;

    IF L_Lock_2_Open AND L_Lock_2_Close THEN
        L_Lock_2_Close := FALSE;
    END_IF;
END_IF;

// ======================================================
// SINGLE POINT WRITE (DETERMINISTIC)
// ======================================================
GVL_COMMAND_SHADOW.G_Gas_Valve_Close := L_Gas_Valve_Close;
GVL_COMMAND_SHADOW.G_Boiler_Stop := L_Boiler_Stop;
GVL_COMMAND_SHADOW.G_Supply_100_Req := L_Supply_100_Req;
GVL_COMMAND_SHADOW.G_Supply_80_Req := L_Supply_80_Req;
GVL_COMMAND_SHADOW.G_Vent_PV3_Boost := L_Vent_PV3_Boost;
GVL_COMMAND_SHADOW.G_Exhaust_100_Req := L_Exhaust_100_Req;
GVL_COMMAND_SHADOW.G_Vent_Stop := L_Vent_Stop;
GVL_COMMAND_SHADOW.G_Vent_Block := L_Vent_Block;
GVL_COMMAND_SHADOW.G_Vent_Smoke_Exhaust := L_Vent_Smoke_Exhaust;

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

// >>> BULK_SYNC_ANCHOR: PRG_Command_Arbitration <<<
END_PROGRAM
