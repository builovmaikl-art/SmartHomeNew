PROGRAM PRG_Modbus_RTU_Driver
VAR
    FB_RTU_Driver : FB_Modbus_RTU_Driver;
END_VAR

// ======================================================
// MODBUS RTU DRIVER EXECUTION
// ======================================================
// Runtime execution wrapper for the RTU driver FB.
//
// Driver_Attached is a configuration/HMI decision and must not depend
// on runtime bridge state.
// ======================================================

FB_RTU_Driver(
    VI_Enable := GVL_CONFIG.G_OpenTherm_Enabled,
    VI_Driver_Attached := GVL_CONFIG.G_Modbus_RTU_Driver_Attached,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

END_PROGRAM
