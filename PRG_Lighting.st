PROGRAM PRG_Lighting
// ==============================================================================
// LIGHTING — deterministic lighting/blinds/socket phase map.
// ==============================================================================
// Execution order is preserved from the former monolithic PRG_Lighting body.
// No gating, shedding or behavior changes are applied here.
// ==============================================================================

PRG_Lighting_Phase_01_Context();
PRG_Lighting_Phase_02_Managers();
PRG_Lighting_Phase_03_Priority_Restrictions();
PRG_Lighting_Phase_04_Output_Publication();

// >>> BULK_SYNC_ANCHOR: PRG_Lighting <<<
END_PROGRAM
