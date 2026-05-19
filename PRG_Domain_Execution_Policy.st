PROGRAM PRG_Domain_Execution_Policy
// Observational domain execution policy.
// Classifies domains as critical, periodic or idle-by-design.
// Does not gate execution and does not write physical outputs.
VAR
    L_i : INT;
    L_Heating_Output_Active : BOOL;
    L_Vent_Output_Active : BOOL;
END_VAR

GVL_DOMAIN_EXECUTION_POLICY.G_Last_Update_MS := GVL_TIME_SERVICE.G_Now_MS;

GVL_DOMAIN_EXECUTION_POLICY.G_Security_Context_Active :=
    GVL_ALARM.G_Security_Armed
    OR GVL_ALARM.G_Security_Alarm;

GVL_DOMAIN_EXECUTION_POLICY.G_Away_Context_Active :=
    GVL_STATUS.G_Current_Scenario = SCENARIO_AWAY;

GVL_DOMAIN_EXECUTION_POLICY.G_Presence_Context_Active :=
    GVL_STATUS.G_Current_Scenario = SCENARIO_PRESENCE;

GVL_DOMAIN_EXECUTION_POLICY.G_Emergency_Context_Active :=
    (GVL_SAFETY_SHUTDOWN.G_Safety_Mode = FIRE)
    OR (GVL_SAFETY_SHUTDOWN.G_Safety_Mode = GAS)
    OR (GVL_SAFETY_SHUTDOWN.G_Safety_Mode = WATER_LEAK)
    OR (GVL_SAFETY_SHUTDOWN.G_Safety_Mode = GLOBAL_STOP);

// ------------------------------------------------------------------------------
// Access policy.
// Critical when emergency semantics or an access command/pulse is active.
// Periodic when security/away context is active, even without a current pulse.
// ------------------------------------------------------------------------------
GVL_DOMAIN_EXECUTION_POLICY.Access_Critical_Run :=
    (GVL_SAFETY_SHUTDOWN.G_Safety_Mode = FIRE)
    OR (GVL_SAFETY_SHUTDOWN.G_Safety_Mode = GAS)
    OR GVL_COMMAND_SHADOW.G_Lock_1_Open
    OR GVL_COMMAND_SHADOW.G_Lock_1_Close
    OR GVL_COMMAND_SHADOW.G_Lock_2_Open
    OR GVL_COMMAND_SHADOW.G_Lock_2_Close
    OR GVL_COMMAND_SHADOW.G_Gate_Open
    OR GVL_COMMAND_SHADOW.G_Wicket_Open
    OR GVL_ACCESS_RUNTIME.G_Any_Pulse_Active;

GVL_DOMAIN_EXECUTION_POLICY.Access_Periodic_Run :=
    (NOT GVL_DOMAIN_EXECUTION_POLICY.Access_Critical_Run)
    AND (
        GVL_DOMAIN_EXECUTION_POLICY.G_Security_Context_Active
        OR GVL_DOMAIN_EXECUTION_POLICY.G_Away_Context_Active
    );

GVL_DOMAIN_EXECUTION_POLICY.Access_Idle_By_Design :=
    NOT GVL_DOMAIN_EXECUTION_POLICY.Access_Critical_Run
    AND NOT GVL_DOMAIN_EXECUTION_POLICY.Access_Periodic_Run;

IF GVL_DOMAIN_EXECUTION_POLICY.Access_Critical_Run THEN
    GVL_DOMAIN_EXECUTION_POLICY.Access_Mode := 2;
ELSIF GVL_DOMAIN_EXECUTION_POLICY.Access_Periodic_Run THEN
    GVL_DOMAIN_EXECUTION_POLICY.Access_Mode := 1;
ELSE
    GVL_DOMAIN_EXECUTION_POLICY.Access_Mode := 0;
END_IF;

// ------------------------------------------------------------------------------
// Lighting policy.
// Critical for fire/evacuation/security alarm/active outputs.
// Periodic for security armed / away / presence scenarios.
// ------------------------------------------------------------------------------
GVL_DOMAIN_EXECUTION_POLICY.Lighting_Critical_Run :=
    (GVL_SAFETY_SHUTDOWN.G_Safety_Mode = FIRE)
    OR GVL_STATE.G_Evacuation_Lighting_Active
    OR GVL_LIGHTING_RUNTIME.G_Emergency_Override_Active
    OR GVL_LIGHTING_RUNTIME.G_Any_Light_Active
    OR GVL_LIGHTING_RUNTIME.G_Any_Blind_Not_Safe_Open
    OR GVL_LIGHTING_RUNTIME.G_Any_Socket_Active
    OR GVL_ALARM.G_Security_Alarm;

GVL_DOMAIN_EXECUTION_POLICY.Lighting_Periodic_Run :=
    (NOT GVL_DOMAIN_EXECUTION_POLICY.Lighting_Critical_Run)
    AND (
        GVL_DOMAIN_EXECUTION_POLICY.G_Security_Context_Active
        OR GVL_DOMAIN_EXECUTION_POLICY.G_Away_Context_Active
        OR GVL_DOMAIN_EXECUTION_POLICY.G_Presence_Context_Active
    );

GVL_DOMAIN_EXECUTION_POLICY.Lighting_Idle_By_Design :=
    NOT GVL_DOMAIN_EXECUTION_POLICY.Lighting_Critical_Run
    AND NOT GVL_DOMAIN_EXECUTION_POLICY.Lighting_Periodic_Run;

IF GVL_DOMAIN_EXECUTION_POLICY.Lighting_Critical_Run THEN
    GVL_DOMAIN_EXECUTION_POLICY.Lighting_Mode := 2;
ELSIF GVL_DOMAIN_EXECUTION_POLICY.Lighting_Periodic_Run THEN
    GVL_DOMAIN_EXECUTION_POLICY.Lighting_Mode := 1;
ELSE
    GVL_DOMAIN_EXECUTION_POLICY.Lighting_Mode := 0;
END_IF;

// ------------------------------------------------------------------------------
// Water policy.
// Critical when leak/global path/output close/recovery is active.
// Periodic when water status has no demand but system is in security/away context.
// ------------------------------------------------------------------------------
GVL_DOMAIN_EXECUTION_POLICY.Water_Critical_Run :=
    (GVL_SAFETY_SHUTDOWN.G_Safety_Mode = WATER_LEAK)
    OR (GVL_SAFETY_SHUTDOWN.G_Safety_Mode = GLOBAL_STOP)
    OR GVL_COMMAND_SHADOW.G_Water_Block
    OR GVL_COMMAND_SHADOW.G_Water_Emergency_Stop
    OR GVL_COMMAND_SHADOW.G_Close_Valve_35
    OR GVL_COMMAND_SHADOW.G_Close_Valve_36
    OR GVL_WATER_DOMAIN_STATUS.G_Recovery_Requested
    OR GVL_WATER_DOMAIN_STATUS.G_Global_Path_Active
    OR GVL_WATER_DOMAIN_STATUS.G_Output_35_Active
    OR GVL_WATER_DOMAIN_STATUS.G_Output_36_Active
    OR GVL_WATER_DOMAIN_STATUS.G_Any_Zone_Active;

GVL_DOMAIN_EXECUTION_POLICY.Water_Periodic_Run :=
    (NOT GVL_DOMAIN_EXECUTION_POLICY.Water_Critical_Run)
    AND (
        GVL_DOMAIN_EXECUTION_POLICY.G_Security_Context_Active
        OR GVL_DOMAIN_EXECUTION_POLICY.G_Away_Context_Active
    );

GVL_DOMAIN_EXECUTION_POLICY.Water_Idle_By_Design :=
    NOT GVL_DOMAIN_EXECUTION_POLICY.Water_Critical_Run
    AND NOT GVL_DOMAIN_EXECUTION_POLICY.Water_Periodic_Run;

IF GVL_DOMAIN_EXECUTION_POLICY.Water_Critical_Run THEN
    GVL_DOMAIN_EXECUTION_POLICY.Water_Mode := 2;
ELSIF GVL_DOMAIN_EXECUTION_POLICY.Water_Periodic_Run THEN
    GVL_DOMAIN_EXECUTION_POLICY.Water_Mode := 1;
ELSE
    GVL_DOMAIN_EXECUTION_POLICY.Water_Mode := 0;
END_IF;

// ------------------------------------------------------------------------------
// Heating policy.
// Critical for emergency/freeze/gas/DHW/block/active outputs.
// Periodic for comfort scenarios or low-demand normal supervision.
// ------------------------------------------------------------------------------
L_Heating_Output_Active :=
    GVL_HEATING_OUTPUT.DO_DHW_Heating_Pump
    OR GVL_HEATING_OUTPUT.DO_DHW_Circ_Pump
    OR GVL_HEATING_OUTPUT.DO_Backup_Circulation_Pump
    OR GVL_HEATING_OUTPUT.DO_Electric_Heater_Enable;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
    L_Heating_Output_Active :=
        L_Heating_Output_Active
        OR GVL_HEATING_OUTPUT.DO_Zone_Valves[L_i];
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    L_Heating_Output_Active :=
        L_Heating_Output_Active
        OR GVL_HEATING_OUTPUT.DO_Manifold_Pumps[L_i]
        OR (GVL_HEATING_OUTPUT.AO_Manifold_Valves[L_i] > 0);
END_FOR;

GVL_DOMAIN_EXECUTION_POLICY.Heating_Critical_Run :=
    (GVL_SAFETY_SHUTDOWN.G_Safety_Mode = GAS)
    OR (GVL_SAFETY_SHUTDOWN.G_Safety_Mode = GLOBAL_STOP)
    OR GVL_COMMAND_SHADOW.G_Heating_Block
    OR GVL_COMMAND_SHADOW.G_Heating_Emergency_Stop
    OR GVL_COMMAND_SHADOW.G_Heating_Gas_Safety_Stop
    OR GVL_STATE.G_Safety_Gas_Latched
    OR GVL_STATE.G_Safety_Freeze_Risk
    OR L_Heating_Output_Active;

GVL_DOMAIN_EXECUTION_POLICY.Heating_Periodic_Run :=
    (NOT GVL_DOMAIN_EXECUTION_POLICY.Heating_Critical_Run)
    AND (
        GVL_STATUS.G_Current_Scenario = SCENARIO_MORNING
        OR GVL_STATUS.G_Current_Scenario = SCENARIO_EVENING
        OR GVL_STATUS.G_Current_Scenario = SCENARIO_SLEEP
        OR GVL_STATUS.G_Current_Scenario = SCENARIO_PRESENCE
        OR GVL_INPUT.IN_Preheat_Request
        OR GVL_INPUT.IN_Freeze_Request
    );

GVL_DOMAIN_EXECUTION_POLICY.Heating_Idle_By_Design :=
    NOT GVL_DOMAIN_EXECUTION_POLICY.Heating_Critical_Run
    AND NOT GVL_DOMAIN_EXECUTION_POLICY.Heating_Periodic_Run;

IF GVL_DOMAIN_EXECUTION_POLICY.Heating_Critical_Run THEN
    GVL_DOMAIN_EXECUTION_POLICY.Heating_Mode := 2;
ELSIF GVL_DOMAIN_EXECUTION_POLICY.Heating_Periodic_Run THEN
    GVL_DOMAIN_EXECUTION_POLICY.Heating_Mode := 1;
ELSE
    GVL_DOMAIN_EXECUTION_POLICY.Heating_Mode := 0;
END_IF;

// ------------------------------------------------------------------------------
// Ventilation policy.
// Critical for gas/fire/smoke/stop/block/emergency boost or active outputs.
// Periodic for occupancy/away/presence/background air-quality supervision.
// ------------------------------------------------------------------------------
L_Vent_Output_Active := GVL_VENT_OUTPUT.DO_Vent_Enable;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SUPPLY_FANS DO
    L_Vent_Output_Active :=
        L_Vent_Output_Active
        OR (GVL_VENT_OUTPUT.AO_Supply_Fans[L_i] > 0);
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_EXHAUST_FANS DO
    L_Vent_Output_Active :=
        L_Vent_Output_Active
        OR (GVL_VENT_OUTPUT.AO_Exhaust_Fans[L_i] > 0);
END_FOR;

GVL_DOMAIN_EXECUTION_POLICY.Vent_Critical_Run :=
    (GVL_SAFETY_SHUTDOWN.G_Safety_Mode = FIRE)
    OR (GVL_SAFETY_SHUTDOWN.G_Safety_Mode = GAS)
    OR (GVL_SAFETY_SHUTDOWN.G_Safety_Mode = GLOBAL_STOP)
    OR GVL_COMMAND_SHADOW.G_Vent_Stop
    OR GVL_COMMAND_SHADOW.G_Vent_Block
    OR GVL_COMMAND_SHADOW.G_Vent_PV3_Boost
    OR GVL_COMMAND_SHADOW.G_Exhaust_100_Req
    OR GVL_COMMAND_SHADOW.G_Vent_Smoke_Exhaust
    OR L_Vent_Output_Active;

GVL_DOMAIN_EXECUTION_POLICY.Vent_Periodic_Run :=
    (NOT GVL_DOMAIN_EXECUTION_POLICY.Vent_Critical_Run)
    AND (
        GVL_DOMAIN_EXECUTION_POLICY.G_Presence_Context_Active
        OR GVL_DOMAIN_EXECUTION_POLICY.G_Away_Context_Active
        OR GVL_INTENT_BEHAVIOR.I_Request_Ventilation_Boost
    );

GVL_DOMAIN_EXECUTION_POLICY.Vent_Idle_By_Design :=
    NOT GVL_DOMAIN_EXECUTION_POLICY.Vent_Critical_Run
    AND NOT GVL_DOMAIN_EXECUTION_POLICY.Vent_Periodic_Run;

IF GVL_DOMAIN_EXECUTION_POLICY.Vent_Critical_Run THEN
    GVL_DOMAIN_EXECUTION_POLICY.Vent_Mode := 2;
ELSIF GVL_DOMAIN_EXECUTION_POLICY.Vent_Periodic_Run THEN
    GVL_DOMAIN_EXECUTION_POLICY.Vent_Mode := 1;
ELSE
    GVL_DOMAIN_EXECUTION_POLICY.Vent_Mode := 0;
END_IF;

// ------------------------------------------------------------------------------
// Simulation policy.
// Runs only when enabled and there is test/security/away/presence context.
// ------------------------------------------------------------------------------
GVL_DOMAIN_EXECUTION_POLICY.Simulation_Context_Active :=
    GVL_SIMULATION.G_Test_Scenario_Active
    OR GVL_SIMULATION.G_Test_Start
    OR GVL_DOMAIN_EXECUTION_POLICY.G_Security_Context_Active
    OR GVL_DOMAIN_EXECUTION_POLICY.G_Away_Context_Active
    OR GVL_DOMAIN_EXECUTION_POLICY.G_Presence_Context_Active;

GVL_DOMAIN_EXECUTION_POLICY.Simulation_Run_Allowed :=
    GVL_SIMULATION.G_Simulation_Enable
    AND GVL_DOMAIN_EXECUTION_POLICY.Simulation_Context_Active
    AND NOT GVL_FABRIC_LIFECYCLE_REGISTRY.Simulation_Suspension_Recommended;

GVL_DOMAIN_EXECUTION_POLICY.Simulation_Idle_By_Design :=
    NOT GVL_DOMAIN_EXECUTION_POLICY.Simulation_Run_Allowed;

IF GVL_DOMAIN_EXECUTION_POLICY.Simulation_Run_Allowed THEN
    GVL_DOMAIN_EXECUTION_POLICY.Simulation_Mode := 1;
ELSE
    GVL_DOMAIN_EXECUTION_POLICY.Simulation_Mode := 0;
END_IF;

// ------------------------------------------------------------------------------
// Summary.
// ------------------------------------------------------------------------------
GVL_DOMAIN_EXECUTION_POLICY.Any_Critical_Run :=
    GVL_DOMAIN_EXECUTION_POLICY.Access_Critical_Run
    OR GVL_DOMAIN_EXECUTION_POLICY.Lighting_Critical_Run
    OR GVL_DOMAIN_EXECUTION_POLICY.Water_Critical_Run
    OR GVL_DOMAIN_EXECUTION_POLICY.Heating_Critical_Run
    OR GVL_DOMAIN_EXECUTION_POLICY.Vent_Critical_Run;

GVL_DOMAIN_EXECUTION_POLICY.Any_Periodic_Run :=
    GVL_DOMAIN_EXECUTION_POLICY.Access_Periodic_Run
    OR GVL_DOMAIN_EXECUTION_POLICY.Lighting_Periodic_Run
    OR GVL_DOMAIN_EXECUTION_POLICY.Water_Periodic_Run
    OR GVL_DOMAIN_EXECUTION_POLICY.Heating_Periodic_Run
    OR GVL_DOMAIN_EXECUTION_POLICY.Vent_Periodic_Run;

GVL_DOMAIN_EXECUTION_POLICY.Any_Idle_By_Design :=
    GVL_DOMAIN_EXECUTION_POLICY.Access_Idle_By_Design
    OR GVL_DOMAIN_EXECUTION_POLICY.Lighting_Idle_By_Design
    OR GVL_DOMAIN_EXECUTION_POLICY.Water_Idle_By_Design
    OR GVL_DOMAIN_EXECUTION_POLICY.Heating_Idle_By_Design
    OR GVL_DOMAIN_EXECUTION_POLICY.Vent_Idle_By_Design
    OR GVL_DOMAIN_EXECUTION_POLICY.Simulation_Idle_By_Design;

IF GVL_DOMAIN_EXECUTION_POLICY.Any_Critical_Run THEN
    GVL_DOMAIN_EXECUTION_POLICY.Status_Code := 2;
    GVL_DOMAIN_EXECUTION_POLICY.Status_Text := 'Domain execution policy critical activity present';
ELSIF GVL_DOMAIN_EXECUTION_POLICY.Any_Periodic_Run THEN
    GVL_DOMAIN_EXECUTION_POLICY.Status_Code := 1;
    GVL_DOMAIN_EXECUTION_POLICY.Status_Text := 'Domain execution policy periodic activity present';
ELSE
    GVL_DOMAIN_EXECUTION_POLICY.Status_Code := 0;
    GVL_DOMAIN_EXECUTION_POLICY.Status_Text := 'Domain execution policy idle by design';
END_IF;

// >>> BULK_SYNC_ANCHOR: PRG_Domain_Execution_Policy <<<
END_PROGRAM
