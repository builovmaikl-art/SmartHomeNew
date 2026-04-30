PROGRAM PRG_System_Runtime_Base
VAR
    fbSystemInit : FB_System_Init;
    fbSystemRecovery : FB_System_Recovery;
    fbSystemPersist : FB_System_Persist_Manager;
    fbSystemRedundancy : FB_System_Redundancy_Orchestrator;
    fbTimebase : FB_System_Timebase;
    fbTime : FB_Time_Service;

    L_Local_State : ST_System_State_Snapshot;
    L_Remote_State : ST_System_State_Snapshot;

    L_Persist_Buffer : ARRAY[0..4] OF BYTE;
    L_Last_Written_Persist_Buffer : ARRAY[0..4] OF BYTE;
    L_Persist_Buffer_Changed : BOOL;
    L_Last_Persist_Write_MS : UDINT;
    L_Recovery_Done : BOOL;
    L_NVRAM_Cmd : BYTE;
    L_NVRAM_Offset : UDINT;
    L_NVRAM_Done : BOOL;
    L_NVRAM_Err : BOOL;
    L_NVRAM_ErrID : UDINT;
END_VAR

fbSystemInit(
    VIO_Local_State := L_Local_State,
    VIO_Remote_State := L_Remote_State
);

fbSystemRecovery(
    VIO_Recovery_Done := L_Recovery_Done
);

// Legacy time bridge retained here until fully removed from runtime base.
fbTimebase();
fbTime();

fbSystemPersist(
    VI_System_Time_MS := GVL_TIME_SERVICE.G_Now_MS,
    VI_IsActivePLC := GVL_STATUS.G_Is_Active_PLC,
    VIO_Persist_Buffer := L_Persist_Buffer,
    VIO_Last_Written_Persist_Buffer := L_Last_Written_Persist_Buffer,
    VIO_Persist_Buffer_Changed := L_Persist_Buffer_Changed,
    VIO_Last_Persist_Write_MS := L_Last_Persist_Write_MS,
    VIO_NVRAM_Cmd := L_NVRAM_Cmd,
    VIO_NVRAM_Offset := L_NVRAM_Offset,
    VIO_NVRAM_Done := L_NVRAM_Done,
    VIO_NVRAM_Err := L_NVRAM_Err,
    VIO_NVRAM_ErrID := L_NVRAM_ErrID
);

fbSystemRedundancy(
    VIO_Local_State := L_Local_State,
    VIO_Remote_State := L_Remote_State
);

END_PROGRAM
