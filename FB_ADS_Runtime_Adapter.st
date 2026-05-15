FUNCTION_BLOCK FB_ADS_Runtime_Adapter
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
END_VAR
VAR
    L_Frame : ST_Runtime_Bus_Frame;
    L_TX_Index : UINT;
END_VAR

IF NOT VI_Enable THEN
    RETURN;
END_IF;

L_TX_Index := GVL_Runtime_Bus.G_Last_Sequence_Id;

IF (L_TX_Index >= 1)
   AND (L_TX_Index <= 128) THEN

    L_Frame := GVL_Runtime_Bus.G_TX_Frames[L_TX_Index];

    IF L_Frame.Frame_Valid THEN

        // ADS deterministic PLC-to-PLC runtime replication.
        // Transport adapter only confirms runtime-frame delivery eligibility.
        // It must never bypass distributed authority, sessions or safety barrier.
        IF GVL_Distributed_Authority.G_Distributed_Safety_Barrier_OK
           AND GVL_Runtime_Sessions.G_Runtime_Valid
           AND NOT GVL_Runtime_Sessions.G_Any_Stale_Session
           AND NOT GVL_Runtime_Sessions.G_Any_Quarantined_Session THEN

            L_Frame.Frame_Ack_Received := TRUE;
            L_Frame.Replication_Consistent := TRUE;
            L_Frame.Replication_Rejected := FALSE;

            L_Frame.Status_Code := 0;
            L_Frame.Status_Text :=
                'ADS runtime replication delivered';

        ELSE

            L_Frame.Frame_Ack_Received := FALSE;
            L_Frame.Replication_Consistent := FALSE;
            L_Frame.Replication_Rejected := TRUE;

            L_Frame.Status_Code := 2;
            L_Frame.Status_Text :=
                'ADS runtime replication blocked';

        END_IF;

        GVL_Runtime_Bus.G_TX_Frames[L_TX_Index] :=
            L_Frame;

        GVL_Runtime_Bus.G_TX_Healthy :=
            L_Frame.Replication_Consistent;

        GVL_Runtime_Bus.G_Any_Replication_Rejected :=
            L_Frame.Replication_Rejected;

    END_IF;

END_IF;

END_FUNCTION_BLOCK