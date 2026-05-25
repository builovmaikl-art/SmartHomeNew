PROGRAM PRG_IO_Read_Phase_02_Discrete_Debounce
// ==============================================================================
// IO READ PHASE 02 — discrete input debounce and mapping.
// ==============================================================================
// Execution order is preserved from the former phase body.
// No gating, shedding or behavior changes are applied here.
// ==============================================================================

PRG_IO_Read_Discrete_01_Lighting_Sockets();
PRG_IO_Read_Discrete_02_Security_Openings();
PRG_IO_Read_Discrete_03_Safety_Sensors();

// >>> BULK_SYNC_ANCHOR: PRG_IO_Read_Phase_02_Discrete_Debounce <<<
END_PROGRAM
