PROGRAM PRG_IO_Read
// ==============================================================================
// IO READ — deterministic physical input acquisition phase map.
// ==============================================================================
// Execution order is preserved from the former monolithic PRG_IO_Read body.
// No gating, shedding or behavior changes are applied here.
// ==============================================================================

PRG_IO_Read_Phase_01_Module_Health();
PRG_IO_Read_Phase_02_Discrete_Debounce();
PRG_IO_Read_Phase_03_Environment_Sensors();
PRG_IO_Read_Phase_04_Heating_Manifold_Sensors();
PRG_IO_Read_Phase_05_Gas_DHW_Water_Feedback();

// >>> BULK_SYNC_ANCHOR: PRG_IO_Read <<<
END_PROGRAM
