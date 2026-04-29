PROGRAM PRG_System_Coordinator
VAR
    fbCoord : FB_System_Coordinator;
END_VAR

fbCoord(
    VI_Fire_Latched := GVL_STATE.G_Safety_Smoke_Latched,
    VI_Gas_Latched := GVL_STATE.G_Safety_Gas_Latched,
    VI_Leak_Latched := GVL_STATE.G_Safety_Leak_Latched,
    VI_IO_Degraded := NOT GVL_STATUS.G_IO_Modules_Online[1],
    VI_Ownership_Violation := GVL_TEST.G_Ownership_Violation,
    VI_Behavior_Mode := GVL_MODE.G_Current_Behavior_Mode
);

GVL_SYSTEM_COORDINATION.G_Block_Heating := fbCoord.VO_Block_Heating OR GVL_HEATING_POLICY.G_Policy_Block_Heating_Request;
GVL_SYSTEM_COORDINATION.G_Block_Ventilation := fbCoord.VO_Block_Ventilation;
GVL_SYSTEM_COORDINATION.G_Block_Lighting_Override := fbCoord.VO_Block_Lighting;
GVL_SYSTEM_COORDINATION.G_Block_Sockets_Override := fbCoord.VO_Block_Sockets;

GVL_SYSTEM_COORDINATION.G_System_Degraded := fbCoord.VO_System_Degraded;
GVL_SYSTEM_COORDINATION.G_Coordination_Code := fbCoord.VO_Code;
