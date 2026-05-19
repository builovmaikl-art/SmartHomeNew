PROGRAM PRG_Main_Phase_02_Redundancy
// MAIN PHASE 03 — redundancy, heartbeat and active/standby arbitration.
// Critical: yes. Called every PLC scan.
VAR
    fbSystemRedundancyOrchestrator : FB_System_Redundancy_Orchestrator;
    fbSystemDiagnostics : FB_System_Diagnostics;
    fbStateReplication : FB_State_Replication;
    fbRedundancyManager : FB_Redundancy_Manager;
    fbPLCHeartbeat : FB_PLC_Heartbeat;

    L_Main_Local_State : ST_System_State_Snapshot;
    L_Main_Remote_State : ST_System_State_Snapshot;
    L_Main_Synced_State : ST_System_State_Snapshot;
    L_Main_State_Updated : BOOL;
    L_Main_PLC_Active : BOOL;
    L_Main_RTT_MS : UDINT;
    L_Main_Loss_Count : UDINT;
    L_Main_Max_RTT : UDINT;
END_VAR

fbPLCHeartbeat(
    VI_Local_ID := GVL_STATUS.G_PLC_ID,
    VI_System_Time := GVL_STATUS.G_System_Time_MS,
    VI_Remote_Pulse := GVL_IO.DI_Partner_Pulse,
    VI_Remote_Is_Active := GVL_IO.DI_Partner_Active,
    VI_Gateway_Ping_OK := GVL_GATEWAY.G_Gateway_Ping_OK,
    VO_Is_Active => L_Main_PLC_Active,
    VO_RTT_MS => L_Main_RTT_MS,
    VO_Loss_Count => L_Main_Loss_Count,
    VO_Max_RTT => L_Main_Max_RTT
);

fbStateReplication(
    VI_Local_Role := SEL(GVL_STATUS.G_Is_Active_PLC, E_PLC_ROLE.ROLE_STANDBY, E_PLC_ROLE.ROLE_ACTIVE),
    VI_Sync_Req := FALSE,
    VI_Local_State := L_Main_Local_State,
    VI_Remote_State := L_Main_Remote_State,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VO_State_Updated => L_Main_State_Updated,
    VO_Synced_State => L_Main_Synced_State
);

fbRedundancyManager(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Local_PLC_ID := GVL_STATUS.G_PLC_ID,
    VI_Remote_Pulse := GVL_IO.DI_Partner_Pulse,
    VI_Remote_Is_Active := GVL_IO.DI_Partner_Active,
    VI_Gateway_Ping_OK := GVL_GATEWAY.G_Gateway_Ping_OK,
    VI_Local_State := L_Main_Local_State,
    VI_Remote_State := L_Main_Remote_State
);

fbSystemDiagnostics();

fbSystemRedundancyOrchestrator(
    VIO_Local_State := L_Main_Local_State,
    VIO_Remote_State := L_Main_Remote_State
);

PRG_Peer_Heartbeat_Ingestion();
PRG_PLC_Arbitration();
PRG_PLC_Fencing_Governor();

// >>> BULK_SYNC_ANCHOR: PRG_Main_Phase_02_Redundancy <<<
END_PROGRAM
