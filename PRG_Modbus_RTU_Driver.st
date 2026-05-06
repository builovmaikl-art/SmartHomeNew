PROGRAM PRG_Modbus_RTU_Driver
VAR
    FB_RTU_Driver : FB_Modbus_RTU_Driver;
END_VAR

// ======================================================
// MODBUS RTU DRIVER EXECUTION
// ======================================================
// Runtime execution wrapper for the RTU driver FB.
// ======================================================

FB_RTU_Driver(
    VI_Enable := GVL_CONFIG.G_OpenTherm_Enabled,
    VI_Driver_Attached := GVL_MODBUS_RTU_BRIDGE.G_Bridge_Enabled,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

END_PROGRAM
