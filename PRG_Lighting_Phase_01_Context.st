PROGRAM PRG_Lighting_Phase_01_Context
VAR
    L_i : INT;
    L_Evac_Blink_Phase : UDINT;
END_VAR

GVL_LIGHTING_RUNTIME_BUFFER.B_Fire_Alarm_Active :=
    GVL_HEALTH_BRIDGE.G_Smoke_Detected
    OR GVL_STATE.G_Safety_Smoke_Latched;

GVL_LIGHTING_RUNTIME_BUFFER.B_Flood_Alarm_Active :=
    GVL_HEALTH_BRIDGE.G_Leak_Detected
    OR GVL_STATE.G_Safety_Leak_Latched;

GVL_LIGHTING_RUNTIME_BUFFER.B_Security_Armed := GVL_ALARM.G_Security_Armed;
GVL_LIGHTING_RUNTIME_BUFFER.B_Security_Alarm := GVL_ALARM.G_Security_Alarm;

L_Evac_Blink_Phase := (GVL_STATUS.G_System_Time_MS / 500) MOD 2;
GVL_LIGHTING_RUNTIME_BUFFER.B_Evac_Blink_On := (L_Evac_Blink_Phase = 0);

GVL_LIGHTING_RUNTIME_BUFFER.B_Distributed_Execute_Allowed :=
    GVL_Distributed_Execution_Gates.G_Can_Execute;

GVL_LIGHTING_RUNTIME_BUFFER.B_Distributed_Projection_Allowed :=
    GVL_Distributed_Execution_Gates.G_Can_Own_Projection;

GVL_LIGHTING_RUNTIME_BUFFER.B_Emergency_Lighting_Override :=
    GVL_STATE.G_Evacuation_Lighting_Active
    OR GVL_LIGHTING_RUNTIME_BUFFER.B_Fire_Alarm_Active;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_LIGHT_ZONES DO
    IF GVL_INTENT_SYSTEM.I_Lighting_Overrides_Block OR GVL_SYSTEM_COORDINATION.G_Block_Lighting_Override THEN
        GVL_LIGHTING_RUNTIME_BUFFER.B_Manual_Light_Override[L_i] := 0;
    ELSE
        GVL_LIGHTING_RUNTIME_BUFFER.B_Manual_Light_Override[L_i] := GVL_INTENT_USER.I_Lighting_Override_32[L_i];
    END_IF;

    GVL_LIGHTING_RUNTIME_BUFFER.B_Sim_Lights[L_i] := GVL_STATE.G_Sim_Lights[L_i];
    GVL_LIGHTING_RUNTIME_BUFFER.B_Physical_Switches[L_i] := GVL_STATE.G_Physical_Switches[L_i];
    GVL_LIGHTING_RUNTIME_BUFFER.B_Motion_Sensors[L_i] := GVL_STATE.G_Motion_Sensors[L_i];

    IF GVL_INTENT_SYSTEM.I_Blinds_Overrides_Block THEN
        GVL_LIGHTING_RUNTIME_BUFFER.B_Manual_Blinds_Override[L_i] := 0;
    ELSE
        GVL_LIGHTING_RUNTIME_BUFFER.B_Manual_Blinds_Override[L_i] := GVL_INTENT_USER.I_Blinds_Override_32[L_i];
    END_IF;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BLINDS DO
    GVL_LIGHTING_RUNTIME_BUFFER.B_Blinds_Override[L_i] :=
        GVL_LIGHTING_RUNTIME_BUFFER.B_Manual_Blinds_Override[L_i];
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SOCKETS DO
    IF GVL_INTENT_SYSTEM.I_Socket_Overrides_Block OR GVL_SYSTEM_COORDINATION.G_Block_Sockets_Override THEN
        GVL_LIGHTING_RUNTIME_BUFFER.B_Manual_Socket_Override[L_i] := FALSE;
    ELSE
        GVL_LIGHTING_RUNTIME_BUFFER.B_Manual_Socket_Override[L_i] := GVL_INTENT_USER.I_Socket_Override_32[L_i];
    END_IF;

    GVL_LIGHTING_RUNTIME_BUFFER.B_Socket_Override[L_i] :=
        GVL_LIGHTING_RUNTIME_BUFFER.B_Manual_Socket_Override[L_i];
END_FOR;

// >>> BULK_SYNC_ANCHOR: PRG_Lighting_Phase_01_Context <<<
END_PROGRAM
