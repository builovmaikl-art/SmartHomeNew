PROGRAM PRG_Main_Phase_05_Domain_Output

GVL_MAIN_PHASE_FEEDBACK.G_Current_Phase := 5;

PRG_Domain_Execution_Policy();
PRG_Domain_Execution_Policy_Periodic();

IF GVL_DOMAIN_EXECUTION_POLICY.Heating_Critical_Run
   OR GVL_DOMAIN_EXECUTION_POLICY.Heating_Periodic_Due THEN
    PRG_Heating();
END_IF;
PRG_Heating_Supervisory_Publication();

IF GVL_DOMAIN_EXECUTION_POLICY.Vent_Critical_Run
   OR GVL_DOMAIN_EXECUTION_POLICY.Vent_Periodic_Due THEN
    PRG_Ventilation();
END_IF;

PRG_Water_Supervisory_Publication();
IF GVL_DOMAIN_EXECUTION_POLICY.Water_Critical_Run
   OR GVL_DOMAIN_EXECUTION_POLICY.Water_Periodic_Due THEN
    PRG_Water_Output_Projection();
    PRG_Water();
END_IF;

IF GVL_DOMAIN_EXECUTION_POLICY.Access_Critical_Run
   OR GVL_DOMAIN_EXECUTION_POLICY.Access_Periodic_Due THEN
    PRG_Access();
END_IF;

IF GVL_DOMAIN_EXECUTION_POLICY.Lighting_Critical_Run
   OR GVL_DOMAIN_EXECUTION_POLICY.Lighting_Periodic_Due THEN
    PRG_Lighting();
END_IF;

PRG_Domain_Execution_Policy();
PRG_Domain_Execution_Policy_Periodic();
PRG_Domain_Execution_Validation();
PRG_Runtime_Scenario_Validation();

PRG_Output_Freshness_Governor();
PRG_Physical_Snapshot_Governor();
PRG_Sensor_Consensus_Governor();
PRG_Telemetry_Causality_Governor();
PRG_Physical_Authority_Epoch_Governor();
PRG_Authority_Lineage_Governor();
PRG_Authority_Revocation_Governor();
PRG_Authority_Restoration_Governor();

PRG_PreOutput_Safety_Barrier();
PRG_IO_Write();
PRG_Runtime_IO_Validation();

GVL_MAIN_PHASE_FEEDBACK.G_Phase_05_Domain_Output_Executed := TRUE;
GVL_MAIN_PHASE_FEEDBACK.G_Phase_05_Domain_Output_Valid :=
    NOT GVL_DOMAIN_EXECUTION_VALIDATION.Any_Policy_Mismatch
    AND NOT GVL_RUNTIME_SCENARIO_VALIDATION.Any_Context_Invalid
    AND NOT GVL_RUNTIME_IO_VALIDATION.Any_IO_Invalid;

IF GVL_DOMAIN_EXECUTION_VALIDATION.Any_Policy_Mismatch THEN
    GVL_MAIN_PHASE_FEEDBACK.G_Phase_05_Domain_Output_Status_Text := 'Domain/output phase validation mismatch';
ELSIF GVL_RUNTIME_SCENARIO_VALIDATION.Any_Context_Invalid THEN
    GVL_MAIN_PHASE_FEEDBACK.G_Phase_05_Domain_Output_Status_Text := 'Domain/output phase scenario mismatch';
ELSIF GVL_RUNTIME_IO_VALIDATION.Any_IO_Invalid THEN
    GVL_MAIN_PHASE_FEEDBACK.G_Phase_05_Domain_Output_Status_Text := 'Domain/output phase physical IO mismatch';
ELSIF GVL_DOMAIN_EXECUTION_POLICY.Any_Idle_By_Design THEN
    GVL_MAIN_PHASE_FEEDBACK.G_Phase_05_Domain_Output_Status_Text := 'Domain/output phase executed with policy gating';
ELSE
    GVL_MAIN_PHASE_FEEDBACK.G_Phase_05_Domain_Output_Status_Text := 'Domain/output phase executed';
END_IF;

GVL_MAIN_PHASE_FEEDBACK.G_Last_Update_MS := GVL_TIME_SERVICE.G_Now_MS;

// >>> BULK_SYNC_ANCHOR: PRG_Main_Phase_05_Domain_Output <<<
END_PROGRAM
