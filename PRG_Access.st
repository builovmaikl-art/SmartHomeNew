PROGRAM PRG_Access
VAR
    fbProjection : FB_Access_Output_Projection;

    fbPulseLock1Open : FB_Access_Pulse_Channel;
    fbPulseLock1Close : FB_Access_Pulse_Channel;
    fbPulseLock2Open : FB_Access_Pulse_Channel;
    fbPulseLock2Close : FB_Access_Pulse_Channel;
    fbPulseGateOpen : FB_Access_Pulse_Channel;
    fbPulseWicketOpen : FB_Access_Pulse_Channel;

    L_Mode : E_Safety_Mode;
    L_Now_MS : UDINT;
    L_Pulse_MS : UDINT;

    L_Distributed_Execute_Allowed : BOOL;
    L_Distributed_Access_Allowed : BOOL;

    L_Lock_1_Open : BOOL;
    L_Lock_1_Close : BOOL;
    L_Lock_2_Open : BOOL;
    L_Lock_2_Close : BOOL;
    L_Gate_Open : BOOL;
    L_Wicket_Open : BOOL;
END_VAR

L_Mode := GVL_SAFETY_SHUTDOWN.G_Safety_Mode;
L_Now_MS := GVL_STATUS.G_System_Time_MS;

GVL_ACCESS_RUNTIME.G_Runtime_Required := FALSE;
GVL_ACCESS_RUNTIME.G_Runtime_Executed := TRUE;
GVL_ACCESS_RUNTIME.G_Runtime_Idle_By_Design := FALSE;
GVL_ACCESS_RUNTIME.G_Runtime_Blocked_By_Distributed_Gates := FALSE;
GVL_ACCESS_RUNTIME.G_Any_Pulse_Active := FALSE;
GVL_ACCESS_RUNTIME.G_Last_Update_MS := L_Now_MS;

// Distributed runtime governance.
// FIRE/GAS emergency semantics remain authoritative.
L_Distributed_Execute_Allowed :=
    GVL_Distributed_Execution_Gates.G_Can_Execute;

L_Distributed_Access_Allowed :=
    GVL_Distributed_Execution_Gates.G_Can_Own_Projection;

IF (L_Mode <> FIRE)
   AND (L_Mode <> GAS)
   AND (
        NOT L_Distributed_Execute_Allowed
        OR NOT L_Distributed_Access_Allowed
       ) THEN

    fbProjection(
        VI_Lock_1_Open := FALSE,
        VI_Lock_1_Close := FALSE,
        VI_Lock_2_Open := FALSE,
        VI_Lock_2_Close := FALSE,
        VI_Gate_Open := FALSE,
        VI_Wicket_Open := FALSE
    );

    GVL_ACCESS_RUNTIME.G_Runtime_Blocked_By_Distributed_Gates := TRUE;
    GVL_ACCESS_RUNTIME.G_Status_Code := 2;
    GVL_ACCESS_RUNTIME.G_Status_Text := 'Access runtime blocked by distributed gates';

    RETURN;
END_IF;

// Load pulse duration from config with safety clamp.
L_Pulse_MS := GVL_CONFIG.G_Access_Pulse_MS;
IF L_Pulse_MS < 100 THEN
    L_Pulse_MS := 100;
ELSIF L_Pulse_MS > 5000 THEN
    L_Pulse_MS := 5000;
END_IF;

L_Lock_1_Open := FALSE;
L_Lock_1_Close := FALSE;
L_Lock_2_Open := FALSE;
L_Lock_2_Close := FALSE;
L_Gate_Open := FALSE;
L_Wicket_Open := FALSE;

CASE L_Mode OF
    FIRE:
        // Fire evacuation access commands are authoritative and continuous.
        L_Lock_1_Open := GVL_COMMAND_SHADOW.G_Lock_1_Open;
        L_Lock_2_Open := GVL_COMMAND_SHADOW.G_Lock_2_Open;
        L_Gate_Open := GVL_COMMAND_SHADOW.G_Gate_Open;
        L_Wicket_Open := GVL_COMMAND_SHADOW.G_Wicket_Open;

        // Synchronize pulse channels with current command state and clear active pulses.
        fbPulseLock1Open(VI_Command := GVL_COMMAND_SHADOW.G_Lock_1_Open, VI_Reset := TRUE, VI_Now_MS := L_Now_MS, VI_Pulse_MS := L_Pulse_MS);
        fbPulseLock1Close(VI_Command := GVL_COMMAND_SHADOW.G_Lock_1_Close, VI_Reset := TRUE, VI_Now_MS := L_Now_MS, VI_Pulse_MS := L_Pulse_MS);
        fbPulseLock2Open(VI_Command := GVL_COMMAND_SHADOW.G_Lock_2_Open, VI_Reset := TRUE, VI_Now_MS := L_Now_MS, VI_Pulse_MS := L_Pulse_MS);
        fbPulseLock2Close(VI_Command := GVL_COMMAND_SHADOW.G_Lock_2_Close, VI_Reset := TRUE, VI_Now_MS := L_Now_MS, VI_Pulse_MS := L_Pulse_MS);
        fbPulseGateOpen(VI_Command := GVL_COMMAND_SHADOW.G_Gate_Open, VI_Reset := TRUE, VI_Now_MS := L_Now_MS, VI_Pulse_MS := L_Pulse_MS);
        fbPulseWicketOpen(VI_Command := GVL_COMMAND_SHADOW.G_Wicket_Open, VI_Reset := TRUE, VI_Now_MS := L_Now_MS, VI_Pulse_MS := L_Pulse_MS);

    GAS:
        // Gas mode uses direct gate opening plus limited pulsed pedestrian/lock release.
        L_Gate_Open := GVL_COMMAND_SHADOW.G_Gate_Open;

        fbPulseLock1Open(VI_Command := GVL_COMMAND_SHADOW.G_Lock_1_Open, VI_Reset := FALSE, VI_Now_MS := L_Now_MS, VI_Pulse_MS := L_Pulse_MS);
        fbPulseLock2Open(VI_Command := GVL_COMMAND_SHADOW.G_Lock_2_Open, VI_Reset := FALSE, VI_Now_MS := L_Now_MS, VI_Pulse_MS := L_Pulse_MS);
        fbPulseWicketOpen(VI_Command := GVL_COMMAND_SHADOW.G_Wicket_Open, VI_Reset := FALSE, VI_Now_MS := L_Now_MS, VI_Pulse_MS := L_Pulse_MS);

        fbPulseLock1Close(VI_Command := GVL_COMMAND_SHADOW.G_Lock_1_Close, VI_Reset := TRUE, VI_Now_MS := L_Now_MS, VI_Pulse_MS := L_Pulse_MS);
        fbPulseLock2Close(VI_Command := GVL_COMMAND_SHADOW.G_Lock_2_Close, VI_Reset := TRUE, VI_Now_MS := L_Now_MS, VI_Pulse_MS := L_Pulse_MS);
        fbPulseGateOpen(VI_Command := GVL_COMMAND_SHADOW.G_Gate_Open, VI_Reset := TRUE, VI_Now_MS := L_Now_MS, VI_Pulse_MS := L_Pulse_MS);

        L_Lock_1_Open := fbPulseLock1Open.VO_Output;
        L_Lock_2_Open := fbPulseLock2Open.VO_Output;
        L_Wicket_Open := fbPulseWicketOpen.VO_Output;

ELSE
        fbPulseLock1Open(VI_Command := GVL_COMMAND_SHADOW.G_Lock_1_Open, VI_Reset := FALSE, VI_Now_MS := L_Now_MS, VI_Pulse_MS := L_Pulse_MS);
        fbPulseLock1Close(VI_Command := GVL_COMMAND_SHADOW.G_Lock_1_Close, VI_Reset := FALSE, VI_Now_MS := L_Now_MS, VI_Pulse_MS := L_Pulse_MS);
        fbPulseLock2Open(VI_Command := GVL_COMMAND_SHADOW.G_Lock_2_Open, VI_Reset := FALSE, VI_Now_MS := L_Now_MS, VI_Pulse_MS := L_Pulse_MS);
        fbPulseLock2Close(VI_Command := GVL_COMMAND_SHADOW.G_Lock_2_Close, VI_Reset := FALSE, VI_Now_MS := L_Now_MS, VI_Pulse_MS := L_Pulse_MS);
        fbPulseGateOpen(VI_Command := GVL_COMMAND_SHADOW.G_Gate_Open, VI_Reset := FALSE, VI_Now_MS := L_Now_MS, VI_Pulse_MS := L_Pulse_MS);
        fbPulseWicketOpen(VI_Command := GVL_COMMAND_SHADOW.G_Wicket_Open, VI_Reset := FALSE, VI_Now_MS := L_Now_MS, VI_Pulse_MS := L_Pulse_MS);

        L_Lock_1_Open := fbPulseLock1Open.VO_Output;
        L_Lock_1_Close := fbPulseLock1Close.VO_Output;
        L_Lock_2_Open := fbPulseLock2Open.VO_Output;
        L_Lock_2_Close := fbPulseLock2Close.VO_Output;
        L_Gate_Open := fbPulseGateOpen.VO_Output;
        L_Wicket_Open := fbPulseWicketOpen.VO_Output;
END_CASE;

GVL_ACCESS_RUNTIME.G_Any_Pulse_Active :=
    fbPulseLock1Open.VO_Active
    OR fbPulseLock1Close.VO_Active
    OR fbPulseLock2Open.VO_Active
    OR fbPulseLock2Close.VO_Active
    OR fbPulseGateOpen.VO_Active
    OR fbPulseWicketOpen.VO_Active;

GVL_ACCESS_RUNTIME.G_Runtime_Required :=
    (L_Mode = FIRE)
    OR (L_Mode = GAS)
    OR GVL_COMMAND_SHADOW.G_Lock_1_Open
    OR GVL_COMMAND_SHADOW.G_Lock_1_Close
    OR GVL_COMMAND_SHADOW.G_Lock_2_Open
    OR GVL_COMMAND_SHADOW.G_Lock_2_Close
    OR GVL_COMMAND_SHADOW.G_Gate_Open
    OR GVL_COMMAND_SHADOW.G_Wicket_Open
    OR GVL_ACCESS_RUNTIME.G_Any_Pulse_Active;

GVL_ACCESS_RUNTIME.G_Runtime_Idle_By_Design :=
    NOT GVL_ACCESS_RUNTIME.G_Runtime_Required;

IF GVL_ACCESS_RUNTIME.G_Runtime_Idle_By_Design THEN
    GVL_ACCESS_RUNTIME.G_Status_Code := 0;
    GVL_ACCESS_RUNTIME.G_Status_Text := 'Access runtime idle by design';
ELSE
    GVL_ACCESS_RUNTIME.G_Status_Code := 1;
    GVL_ACCESS_RUNTIME.G_Status_Text := 'Access runtime active';
END_IF;

fbProjection(
    VI_Lock_1_Open := L_Lock_1_Open,
    VI_Lock_1_Close := L_Lock_1_Close,
    VI_Lock_2_Open := L_Lock_2_Open,
    VI_Lock_2_Close := L_Lock_2_Close,
    VI_Gate_Open := L_Gate_Open,
    VI_Wicket_Open := L_Wicket_Open
);

// >>> BULK_SYNC_ANCHOR: PRG_Access <<<
END_PROGRAM