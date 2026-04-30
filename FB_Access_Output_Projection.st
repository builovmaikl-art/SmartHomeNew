FUNCTION_BLOCK FB_Access_Output_Projection
VAR_INPUT
    VI_Lock_1_Open : BOOL;
    VI_Lock_1_Close : BOOL;
    VI_Lock_2_Open : BOOL;
    VI_Lock_2_Close : BOOL;
    VI_Gate_Open : BOOL;
    VI_Wicket_Open : BOOL;
END_VAR

GVL_ACCESS_OUTPUT.DO_Lock_1_Open := VI_Lock_1_Open;
GVL_ACCESS_OUTPUT.DO_Lock_1_Close := VI_Lock_1_Close;
GVL_ACCESS_OUTPUT.DO_Lock_2_Open := VI_Lock_2_Open;
GVL_ACCESS_OUTPUT.DO_Lock_2_Close := VI_Lock_2_Close;
GVL_ACCESS_OUTPUT.DO_Gate_Open := VI_Gate_Open;
GVL_ACCESS_OUTPUT.DO_Wicket_Open := VI_Wicket_Open;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Access_Output_Projection <<<
