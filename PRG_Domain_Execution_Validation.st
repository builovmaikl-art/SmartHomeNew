PROGRAM PRG_Domain_Execution_Validation
// Observational validation for policy-gated domain execution.
// Detects stale-output risks when a domain is classified idle.
VAR
    L_i : INT;
    L_Access_Output_Active : BOOL;
    L_Lighting_Output_Active : BOOL;
    L_Water_Output_Active : BOOL;
    L_Heating_Output_Active : BOOL;
    L_Vent_Output_Active : BOOL;
END_VAR

GVL_DOMAIN_EXECUTION_VALIDATION.G_Last_Update_MS := GVL_TIME_SERVICE.G_Now_MS;
GVL_DOMAIN_EXECUTION_VALIDATION.G_Validation_Executed := TRUE;
GVL_DOMAIN_EXECUTION_VALIDATION.G_Validation_Valid := TRUE;

L_Access_Output_Active :=
    GVL_ACCESS_OUTPUT.DO_Lock_1_Open
    OR GVL_ACCESS_OUTPUT.DO_Lock_1_Close
    OR GVL_ACCESS_OUTPUT.DO_Lock_2_Open
    OR GVL_ACCESS_OUTPUT.DO_Lock_2_Close
    OR GVL_ACCESS_OUTPUT.DO_Gate_Open
    OR GVL_ACCESS_OUTPUT.DO_Wicket_Open;

L_Lighting_Output_Active := FALSE;
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_LIGHT_ZONES DO
    L_Lighting_Output_Active :=
        L_Lighting_Output_Active
        OR (GVL_LIGHTING_OUTPUT.AO_Lighting_Levels[L_i] > 0);
END_FOR;
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BLINDS DO
    L_Lighting_Output_Active :=
        L_Lighting_Output_Active
        OR (GVL_LIGHTING_OUTPUT.AO_Blinds_Positions[L_i] < 1000);
END_FOR;
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SOCKETS DO
    L_Lighting_Output_Active :=
        L_Lighting_Output_Active
        OR GVL_LIGHTING_OUTPUT.DO_Sockets[L_i];
END_FOR;

L_Water_Output_Active :=
    GVL_WATER_OUTPUT.DO_Water_Valve_35_Close
    OR GVL_WATER_OUTPUT.DO_Water_Valve_36_Close;
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_WATER_ZONES DO
    L_Water_Output_Active :=
        L_Water_Output_Active
        OR GVL_WATER_OUTPUT.DO_Water_Zone_Enable[L_i];
END_FOR;

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

GVL_DOMAIN_EXECUTION_VALIDATION.Access_Stale_Output_Risk :=
    GVL_DOMAIN_EXECUTION_POLICY.Access_Idle_By_Design AND L_Access_Output_Active;

GVL_DOMAIN_EXECUTION_VALIDATION.Lighting_Stale_Output_Risk :=
    GVL_DOMAIN_EXECUTION_POLICY.Lighting_Idle_By_Design AND L_Lighting_Output_Active;

GVL_DOMAIN_EXECUTION_VALIDATION.Water_Stale_Output_Risk :=
    GVL_DOMAIN_EXECUTION_POLICY.Water_Idle_By_Design AND L_Water_Output_Active;

GVL_DOMAIN_EXECUTION_VALIDATION.Heating_Stale_Output_Risk :=
    GVL_DOMAIN_EXECUTION_POLICY.Heating_Idle_By_Design AND L_Heating_Output_Active;

GVL_DOMAIN_EXECUTION_VALIDATION.Vent_Stale_Output_Risk :=
    GVL_DOMAIN_EXECUTION_POLICY.Vent_Idle_By_Design AND L_Vent_Output_Active;

GVL_DOMAIN_EXECUTION_VALIDATION.Any_Stale_Output_Risk :=
    GVL_DOMAIN_EXECUTION_VALIDATION.Access_Stale_Output_Risk
    OR GVL_DOMAIN_EXECUTION_VALIDATION.Lighting_Stale_Output_Risk
    OR GVL_DOMAIN_EXECUTION_VALIDATION.Water_Stale_Output_Risk
    OR GVL_DOMAIN_EXECUTION_VALIDATION.Heating_Stale_Output_Risk
    OR GVL_DOMAIN_EXECUTION_VALIDATION.Vent_Stale_Output_Risk;

GVL_DOMAIN_EXECUTION_VALIDATION.Any_Policy_Mismatch :=
    GVL_DOMAIN_EXECUTION_VALIDATION.Any_Stale_Output_Risk;

IF GVL_DOMAIN_EXECUTION_VALIDATION.Any_Stale_Output_Risk THEN
    GVL_DOMAIN_EXECUTION_VALIDATION.G_Validation_Valid := FALSE;
    GVL_DOMAIN_EXECUTION_VALIDATION.Status_Code := 1;
    GVL_DOMAIN_EXECUTION_VALIDATION.Status_Text := 'Domain execution validation detected stale output risk';
ELSE
    GVL_DOMAIN_EXECUTION_VALIDATION.Status_Code := 0;
    GVL_DOMAIN_EXECUTION_VALIDATION.Status_Text := 'Domain execution validation nominal';
END_IF;

// >>> BULK_SYNC_ANCHOR: PRG_Domain_Execution_Validation <<<
END_PROGRAM
