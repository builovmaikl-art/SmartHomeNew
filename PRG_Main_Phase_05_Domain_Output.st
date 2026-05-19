PROGRAM PRG_Main_Phase_05_Domain_Output
// MAIN PHASE 09/10/11 — domain control, output validation and physical IO projection.
// Critical: yes. This is the physical actuation path and must run every PLC scan.

GVL_MAIN_PHASE_FEEDBACK.G_Current_Phase := 5;

PRG_Heating();
PRG_Heating_Supervisory_Publication();
PRG_Ventilation();
PRG_Water_Supervisory_Publication();
PRG_Water_Output_Projection();
PRG_Water();
PRG_Access();
PRG_Lighting();

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

GVL_MAIN_PHASE_FEEDBACK.G_Phase_05_Domain_Output_Executed := TRUE;
GVL_MAIN_PHASE_FEEDBACK.G_Phase_05_Domain_Output_Valid := TRUE;
GVL_MAIN_PHASE_FEEDBACK.G_Phase_05_Domain_Output_Status_Text := 'Domain/output phase executed';
GVL_MAIN_PHASE_FEEDBACK.G_Last_Update_MS := GVL_TIME_SERVICE.G_Now_MS;

// >>> BULK_SYNC_ANCHOR: PRG_Main_Phase_05_Domain_Output <<<
END_PROGRAM
