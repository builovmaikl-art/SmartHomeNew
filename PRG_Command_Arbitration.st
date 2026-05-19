PROGRAM PRG_Command_Arbitration
// ==============================================================================
// COMMAND ARBITRATION — deterministic command-shadow phase map.
// ==============================================================================
// Execution preserves the former priority model:
// 1. reset + PLC role guard
// 2. safety mode projection
// 3. safe user/rule projection and conflict cleanup
// 4. single deterministic write into GVL_COMMAND_SHADOW
// ==============================================================================

PRG_Command_Arbitration_Phase_01_Reset_Role();

IF GVL_COMMAND_ARBITRATION_BUFFER.B_Role_Conflict_Active
   OR GVL_COMMAND_ARBITRATION_BUFFER.B_PLC_Inactive_Active THEN
    PRG_Command_Arbitration_Phase_04_Write_Shadow();
    RETURN;
END_IF;

PRG_Command_Arbitration_Phase_02_Safety_Mode();
PRG_Command_Arbitration_Phase_03_User_Rules_Conflict();
PRG_Command_Arbitration_Phase_04_Write_Shadow();

// >>> BULK_SYNC_ANCHOR: PRG_Command_Arbitration <<<
END_PROGRAM
