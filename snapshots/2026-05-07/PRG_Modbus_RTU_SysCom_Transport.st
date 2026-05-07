PROGRAM PRG_Modbus_RTU_SysCom_Transport
VAR
    FB_SysCom_Transport : FB_Modbus_RTU_SysCom_Transport;
END_VAR

// ======================================================
// MODBUS RTU SYSCOM TRANSPORT EXECUTION
// ======================================================
// Byte-level transport boundary execution.
// ======================================================

FB_SysCom_Transport(
    VI_Enable := GVL_CONFIG.G_OpenTherm_Enabled,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

END_PROGRAM
