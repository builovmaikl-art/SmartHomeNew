FUNCTION F_Modbus_RTU_CRC16 : WORD
VAR_INPUT
    VI_Data : ARRAY[0..255] OF BYTE;
    VI_Length : UINT;
END_VAR

// ======================================================
// LEGACY CRC16 COMPATIBILITY FUNCTION
// ======================================================
// Kept only for backward compatibility.
// Active runtime now uses inline CRC implementations
// inside TX builder, RX parser and SysCom backend.
// ======================================================

F_Modbus_RTU_CRC16 := WORD#16#FFFF;

END_FUNCTION
