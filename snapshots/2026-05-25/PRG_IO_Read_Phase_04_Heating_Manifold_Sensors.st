PROGRAM PRG_IO_Read_Phase_04_Heating_Manifold_Sensors
// ==============================================================================
// IO READ PHASE 04 — heating manifold analog sensors and status inputs.
// ==============================================================================
// Execution order is preserved from the former phase body.
// No gating, shedding or behavior changes are applied here.
// ==============================================================================

PRG_IO_Read_Manifold_01_Pressure_Current();
PRG_IO_Read_Manifold_02_Temperature_Status();

// >>> BULK_SYNC_ANCHOR: PRG_IO_Read_Phase_04_Heating_Manifold_Sensors <<<
END_PROGRAM
