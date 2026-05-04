PROGRAM PRG_Access
VAR
    fbProjection : FB_Access_Output_Projection;
END_VAR

fbProjection(
    VI_Lock_1_Open := GVL_COMMAND_SHADOW.G_Lock_1_Open,
    VI_Lock_1_Close := GVL_COMMAND_SHADOW.G_Lock_1_Close,
    VI_Lock_2_Open := GVL_COMMAND_SHADOW.G_Lock_2_Open,
    VI_Lock_2_Close := GVL_COMMAND_SHADOW.G_Lock_2_Close,
    VI_Gate_Open := GVL_COMMAND_SHADOW.G_Gate_Open,
    VI_Wicket_Open := GVL_COMMAND_SHADOW.G_Wicket_Open
);

// >>> BULK_SYNC_ANCHOR: PRG_Access <<<
END_PROGRAM
