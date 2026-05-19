PROGRAM PRG_Modbus_RTU_SysCom_Backend
VAR
    FB_Backend : FB_Modbus_RTU_SysCom_Backend;
END_VAR

FB_Backend(
    VI_Enable := GVL_CONFIG.G_OpenTherm_Enabled,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

END_PROGRAM
