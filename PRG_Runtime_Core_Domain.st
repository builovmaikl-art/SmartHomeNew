PROGRAM PRG_Runtime_Core_Domain
// CANONICAL EXECUTION DOMAIN
// PRESERVES EXECUTION ORDER

PRG_Time_Service();
PRG_System_Init();
PRG_Runtime_Barrier();
PRG_Runtime_Snapshot_Governor();
PRG_Runtime_Assumption_Integrity_Governor();

END_PROGRAM