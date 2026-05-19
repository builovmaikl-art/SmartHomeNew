PROGRAM PRG_Main_Phase_06_PostOutput_Authority
// MAIN PHASE 12A — post-output authority, physical transaction and causality guards.
// Critical: high. Runs after IO projection to validate authority/physical consistency.

PRG_Actuation_Authority_Governor();
PRG_Physical_Transaction_Governor();
PRG_Temporal_Stability_Governor();
PRG_Environmental_Authority_Governor();
PRG_Runtime_Resource_Authority_Governor();
PRG_Semantic_Continuity_Authority_Governor();
PRG_Observability_Truth_Governor();
PRG_Historical_Truth_Governor();
PRG_Global_Authority_Sync_Governor();
PRG_Control_Temporal_Coherence_Governor();
PRG_Actuator_Semantic_Verification_Governor();
PRG_Energy_Causality_Governor();
PRG_Runtime_Sustainability_Governor();

// >>> BULK_SYNC_ANCHOR: PRG_Main_Phase_06_PostOutput_Authority <<<
END_PROGRAM
