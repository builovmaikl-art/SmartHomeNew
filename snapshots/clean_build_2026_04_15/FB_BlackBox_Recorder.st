FUNCTION_BLOCK FB_BlackBox_Recorder
VAR_INPUT
    VI_Current_Data : ST_BlackBox_Record;
    VI_Freeze       : BOOL;
END_VAR
VAR_OUTPUT
    VO_Frozen       : BOOL;
    VO_Records_Count: INT;
END_VAR
VAR
    L_Write_Index   : INT := 0;
    L_Initialized   : BOOL := FALSE;
END_VAR

IF NOT L_Initialized THEN
    L_Write_Index := GVL_Retain.G_BlackBox_LastIndex;
    IF L_Write_Index < 0 OR L_Write_Index >= GVL_CONSTANTS.C_MAX_BLACKBOX_RECORDS THEN
        L_Write_Index := 0;
        GVL_Retain.G_BlackBox_LastIndex := 0;
    END_IF;
    L_Initialized := TRUE;
END_IF;

IF VI_Freeze THEN
    GVL_Retain.G_BlackBox_Frozen := TRUE;
END_IF;

VO_Frozen := GVL_Retain.G_BlackBox_Frozen;

IF NOT GVL_Retain.G_BlackBox_Frozen THEN
    GVL_Retain.G_BlackBox_Buffer[L_Write_Index] := VI_Current_Data;
    GVL_Retain.G_BlackBox_LastIndex := L_Write_Index;
    
    L_Write_Index := L_Write_Index + 1;
    IF L_Write_Index >= GVL_CONSTANTS.C_MAX_BLACKBOX_RECORDS THEN
        L_Write_Index := 0;
    END_IF;
END_IF;

VO_Records_Count := GVL_CONSTANTS.C_MAX_BLACKBOX_RECORDS; // Размер кольцевого буфера
// >>> BULK_SYNC_ANCHOR: FB_BlackBox_Recorder <<<
