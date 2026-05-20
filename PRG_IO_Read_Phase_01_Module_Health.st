PROGRAM PRG_IO_Read_Phase_01_Module_Health
VAR
    fbIO_Watchdog_1 : FB_IO_Module_Watchdog;
    fbIO_Watchdog_2 : FB_IO_Module_Watchdog;
    fbDiagEventManager : FB_Diagnostics_Event_Manager;
    L_IO_Error_Active : BOOL;
    L_i : INT;
END_VAR

// Default unused module slots to online so domain loops over C_MAX_MODULES
// do not report false faults for modules without watchdog bindings.
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MODULES DO
    GVL_STATUS.G_IO_Modules_Online[L_i] := TRUE;
END_FOR;

fbIO_Watchdog_1(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Module_ID := 1,
    VI_Heartbeat_Signal := GVL_IO.DI_Module_1_Heartbeat,
    VI_Timeout_MS := 2000
);

fbIO_Watchdog_2(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Module_ID := 2,
    VI_Heartbeat_Signal := GVL_IO.DI_Module_2_Heartbeat,
    VI_Timeout_MS := 2000
);

GVL_STATUS.G_IO_Modules_Online[1] := fbIO_Watchdog_1.VO_Module_Online;
GVL_STATUS.G_IO_Modules_Online[2] := fbIO_Watchdog_2.VO_Module_Online;

L_IO_Error_Active := fbIO_Watchdog_1.VO_Error_Active OR fbIO_Watchdog_2.VO_Error_Active;

fbDiagEventManager(
    VI_Code := 16#E001,
    VI_Severity := 4,
    VI_Active := NOT fbIO_Watchdog_1.VO_Module_Online,
    VI_Timestamp := GVL_STATUS.G_System_Time_MS,
    VI_Source := 1,
    VIO_Events := GVL_STATUS.G_Diagnostics_Events,
    VIO_Count := GVL_STATUS.G_Diagnostics_Count
);

fbDiagEventManager(
    VI_Code := 16#E002,
    VI_Severity := 4,
    VI_Active := NOT fbIO_Watchdog_2.VO_Module_Online,
    VI_Timestamp := GVL_STATUS.G_System_Time_MS,
    VI_Source := 2,
    VIO_Events := GVL_STATUS.G_Diagnostics_Events,
    VIO_Count := GVL_STATUS.G_Diagnostics_Count
);

// >>> BULK_SYNC_ANCHOR: PRG_IO_Read_Phase_01_Module_Health <<<
END_PROGRAM
