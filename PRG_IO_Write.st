PROGRAM PRG_IO_Write
// ==============================================================================
// IO WRITE — deterministic physical output publication phase map.
// ==============================================================================
// Execution preserves the former priority model:
// 1. derive publication guards and forced-off flags
// 2. hard-stop safe-state publication and return when required
// 3. normal domain output projection
// 4. final alarm/gas valve and trace publication
// ==============================================================================

PRG_IO_Write_Phase_01_Context();

IF (NOT GVL_STATUS.G_Is_Active_PLC)
   OR GVL_IO_WRITE_RUNTIME_BUFFER.B_Global_Hard_Stop THEN
    PRG_IO_Write_Phase_02_Hard_Stop_Safe_State();
    RETURN;
END_IF;

PRG_IO_Write_Phase_03_Domain_Projection();
PRG_IO_Write_Phase_04_Alarm_Trace();

// >>> BULK_SYNC_ANCHOR: PRG_IO_Write <<<
END_PROGRAM
