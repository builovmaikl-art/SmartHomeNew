PROGRAM PRG_Main_Phase_02_Redundancy
// MAIN PHASE 02 — local PLC authority / cold-spare model.
// Critical: yes. Called every PLC scan.
//
// Current architecture: one active PLC controls the system; a second PLC is a
// cold spare only and must not participate in runtime ownership, hot failover,
// direct state replication or physical output arbitration.
VAR
    fbSystemDiagnostics : FB_System_Diagnostics;
    fbServiceHeartbeatTimer : FB_System_Timer;
    L_Service_Heartbeat_State : BOOL;
END_VAR

GVL_MAIN_PHASE_FEEDBACK.G_Current_Phase := 2;

// Local-only authority. No hot standby arbitration is performed in runtime.
GVL_STATUS.G_Is_Active_PLC := TRUE;
GVL_STATUS.G_Other_PLC_Is_Active := FALSE;
GVL_STATUS.G_Remote_PLC_Alive := FALSE;
GVL_STATUS.G_Remote_PLC_Pulse := FALSE;
GVL_STATUS.G_Active_PLC_ID := GVL_STATUS.G_Local_PLC_ID;

// Physical/service status outputs. The heartbeat output is only a local service
// indicator and is not used for automatic failover.
fbServiceHeartbeatTimer(
    IN := NOT fbServiceHeartbeatTimer.Q,
    PT := T#500ms,
    VI_System_Time_MS := GVL_TIME_SERVICE.G_Now_MS
);

IF fbServiceHeartbeatTimer.Q THEN
    L_Service_Heartbeat_State := NOT L_Service_Heartbeat_State;
END_IF;

GVL_IO.DO_Heartbeat_Pulse := L_Service_Heartbeat_State;
GVL_IO.DO_Active_Status := TRUE;

fbSystemDiagnostics();
PRG_PLC_Arbitration();
PRG_PLC_Fencing_Governor();

GVL_MAIN_PHASE_FEEDBACK.G_Phase_02_Redundancy_Executed := TRUE;
GVL_MAIN_PHASE_FEEDBACK.G_Phase_02_Redundancy_Valid := TRUE;
GVL_MAIN_PHASE_FEEDBACK.G_Phase_02_Redundancy_Status_Text := 'Single active PLC / cold-spare authority phase executed';
GVL_MAIN_PHASE_FEEDBACK.G_Last_Update_MS := GVL_TIME_SERVICE.G_Now_MS;

// >>> BULK_SYNC_ANCHOR: PRG_Main_Phase_02_Redundancy <<<
END_PROGRAM