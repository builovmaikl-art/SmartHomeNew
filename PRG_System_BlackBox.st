PROGRAM PRG_System_BlackBox
VAR
    fbBlackBox : FB_BlackBox_Recorder;
    L_BB_Record : ST_BlackBox_Record;
    L_BB_Freeze : BOOL;
    L_BB_Gas_Active : BOOL;
    L_BB_Fire_Active : BOOL;
    L_BB_Flood_Active : BOOL;
END_VAR

// BlackBox must record authoritative safety truth and latches,
// not stale alarm projection fields.
L_BB_Gas_Active := GVL_HEALTH_BRIDGE.G_Gas_Detected OR GVL_HEALTH_BRIDGE.G_CO_Alarm_Level OR GVL_STATE.G_Safety_Gas_Latched;
L_BB_Fire_Active := GVL_HEALTH_BRIDGE.G_Smoke_Detected OR GVL_STATE.G_Safety_Smoke_Latched;
L_BB_Flood_Active := GVL_HEALTH_BRIDGE.G_Leak_Detected OR GVL_STATE.G_Safety_Leak_Latched;

L_BB_Record.Timestamp := GVL_TIME_SERVICE.G_Now_MS;
L_BB_Record.PLC_Active_ID := GVL_STATUS.G_PLC_ID;
L_BB_Record.Gas_Methane_LEL := GVL_STATE.G_Methane_Sensors[1];
L_BB_Record.Gas_CO_PPM := GVL_STATE.G_CO_Sensors[1];
L_BB_Record.Flood_Active := L_BB_Flood_Active;
L_BB_Record.Fire_Active := L_BB_Fire_Active;

L_BB_Record.System_Mode := TO_BYTE(TO_INT(GVL_STATE.G_System_Mode));
L_BB_Record.First_Fault_Type := TO_BYTE(GVL_SYSTEM_HEALTH.G_First_Fault_Type);
L_BB_Record.First_Fault_Source := TO_BYTE(GVL_SYSTEM_HEALTH.G_First_Fault_Source);
L_BB_Record.First_Fault_Active := GVL_SYSTEM_HEALTH.G_First_Fault_Active;
L_BB_Record.System_Severity := TO_BYTE(GVL_SYSTEM_HEALTH.G_System_Severity);
L_BB_Record.Root_Cause := TO_BYTE(GVL_SYSTEM_HEALTH.G_Root_Cause);
L_BB_Record.Watchdog_Fault := GVL_SYSTEM_HEALTH.G_Watchdog_Fault;

L_BB_Freeze := L_BB_Gas_Active OR L_BB_Fire_Active OR L_BB_Flood_Active OR GVL_SYSTEM_HEALTH.G_First_Fault_Active;

fbBlackBox(
    VI_Current_Data := L_BB_Record,
    VI_Freeze := L_BB_Freeze
);

END_PROGRAM
