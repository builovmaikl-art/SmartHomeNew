PROGRAM PRG_File_Archive_HMI_Applicator
// ==============================================================================
// FILE ARCHIVE HMI APPLICATOR — validates HMI intent and updates archive runtime.
// ==============================================================================
// HMI is not allowed to write files or physical outputs directly. This program
// only transfers validated one-shot requests/configuration into GVL_FILE_ARCHIVE,
// where PRG_File_Archive_Manager consumes them and publishes deterministic status.
// ==============================================================================
VAR
    L_Any_Write_Request : BOOL;
END_VAR

L_Any_Write_Request :=
    GVL_FILE_ARCHIVE_HMI.G_Write_Event_CSV_Req
    OR GVL_FILE_ARCHIVE_HMI.G_Write_Trend_CSV_Req
    OR GVL_FILE_ARCHIVE_HMI.G_Write_BlackBox_CSV_Req
    OR GVL_FILE_ARCHIVE_HMI.G_Write_Config_Backup_Req;

IF GVL_FILE_ARCHIVE_HMI.G_Set_Archive_Config_Req THEN
    IF GVL_FILE_ARCHIVE_HMI.G_File_Archive_Target_Code <= 3 THEN
        GVL_FILE_ARCHIVE.G_Archive_Interface_Enabled := GVL_FILE_ARCHIVE_HMI.G_Archive_Interface_Enabled;
        GVL_FILE_ARCHIVE.G_CSV_Write_Enabled := GVL_FILE_ARCHIVE_HMI.G_CSV_Write_Enabled;
        GVL_FILE_ARCHIVE.G_File_Archive_Target_Code := GVL_FILE_ARCHIVE_HMI.G_File_Archive_Target_Code;

        GVL_FILE_ARCHIVE.G_Write_Busy := FALSE;
        GVL_FILE_ARCHIVE.G_Write_Done := TRUE;
        GVL_FILE_ARCHIVE.G_Write_Error := FALSE;
        GVL_FILE_ARCHIVE.G_Last_Error_Code := 0;
        GVL_FILE_ARCHIVE.G_Last_Status_Text := 'Archive configuration applied';
        GVL_FILE_ARCHIVE.G_Last_Write_MS := GVL_TIME_SERVICE.G_Now_MS;

        GVL_FILE_ARCHIVE_HMI.G_Last_Error := FALSE;
        GVL_FILE_ARCHIVE_HMI.G_Last_Error_Code := 0;
        GVL_FILE_ARCHIVE_HMI.G_Last_Status_Text := 'Archive configuration applied';
    ELSE
        GVL_FILE_ARCHIVE.G_Write_Busy := FALSE;
        GVL_FILE_ARCHIVE.G_Write_Done := FALSE;
        GVL_FILE_ARCHIVE.G_Write_Error := TRUE;
        GVL_FILE_ARCHIVE.G_Last_Error_Code := 16#A101;
        GVL_FILE_ARCHIVE.G_Last_Status_Text := 'Archive configuration rejected: invalid target';
        GVL_FILE_ARCHIVE.G_Last_Write_MS := GVL_TIME_SERVICE.G_Now_MS;

        GVL_FILE_ARCHIVE_HMI.G_Last_Error := TRUE;
        GVL_FILE_ARCHIVE_HMI.G_Last_Error_Code := 16#A101;
        GVL_FILE_ARCHIVE_HMI.G_Last_Status_Text := 'Archive configuration rejected: invalid target';
    END_IF;

    GVL_FILE_ARCHIVE_HMI.G_Last_Update_MS := GVL_TIME_SERVICE.G_Now_MS;
    GVL_FILE_ARCHIVE_HMI.G_Set_Archive_Config_Req := FALSE;
END_IF;

IF L_Any_Write_Request THEN
    IF NOT GVL_FILE_ARCHIVE.G_Archive_Interface_Enabled THEN
        GVL_FILE_ARCHIVE.G_Write_Busy := FALSE;
        GVL_FILE_ARCHIVE.G_Write_Done := FALSE;
        GVL_FILE_ARCHIVE.G_Write_Error := TRUE;
        GVL_FILE_ARCHIVE.G_Last_Error_Code := 16#A102;
        GVL_FILE_ARCHIVE.G_Last_Status_Text := 'Archive write rejected: interface disabled';
        GVL_FILE_ARCHIVE.G_Last_Write_MS := GVL_TIME_SERVICE.G_Now_MS;

        GVL_FILE_ARCHIVE_HMI.G_Last_Error := TRUE;
        GVL_FILE_ARCHIVE_HMI.G_Last_Error_Code := 16#A102;
        GVL_FILE_ARCHIVE_HMI.G_Last_Status_Text := 'Archive write rejected: interface disabled';
    ELSIF NOT GVL_FILE_ARCHIVE.G_CSV_Write_Enabled THEN
        GVL_FILE_ARCHIVE.G_Write_Busy := FALSE;
        GVL_FILE_ARCHIVE.G_Write_Done := FALSE;
        GVL_FILE_ARCHIVE.G_Write_Error := TRUE;
        GVL_FILE_ARCHIVE.G_Last_Error_Code := 16#A103;
        GVL_FILE_ARCHIVE.G_Last_Status_Text := 'Archive write rejected: CSV disabled';
        GVL_FILE_ARCHIVE.G_Last_Write_MS := GVL_TIME_SERVICE.G_Now_MS;

        GVL_FILE_ARCHIVE_HMI.G_Last_Error := TRUE;
        GVL_FILE_ARCHIVE_HMI.G_Last_Error_Code := 16#A103;
        GVL_FILE_ARCHIVE_HMI.G_Last_Status_Text := 'Archive write rejected: CSV disabled';
    ELSE
        GVL_FILE_ARCHIVE.G_Write_Event_CSV_Request :=
            GVL_FILE_ARCHIVE.G_Write_Event_CSV_Request OR GVL_FILE_ARCHIVE_HMI.G_Write_Event_CSV_Req;
        GVL_FILE_ARCHIVE.G_Write_Trend_CSV_Request :=
            GVL_FILE_ARCHIVE.G_Write_Trend_CSV_Request OR GVL_FILE_ARCHIVE_HMI.G_Write_Trend_CSV_Req;
        GVL_FILE_ARCHIVE.G_Write_BlackBox_CSV_Request :=
            GVL_FILE_ARCHIVE.G_Write_BlackBox_CSV_Request OR GVL_FILE_ARCHIVE_HMI.G_Write_BlackBox_CSV_Req;
        GVL_FILE_ARCHIVE.G_Write_Config_Backup_Request :=
            GVL_FILE_ARCHIVE.G_Write_Config_Backup_Request OR GVL_FILE_ARCHIVE_HMI.G_Write_Config_Backup_Req;

        GVL_FILE_ARCHIVE_HMI.G_Last_Error := FALSE;
        GVL_FILE_ARCHIVE_HMI.G_Last_Error_Code := 0;
        GVL_FILE_ARCHIVE_HMI.G_Last_Status_Text := 'Archive write request accepted';
    END_IF;

    GVL_FILE_ARCHIVE_HMI.G_Last_Update_MS := GVL_TIME_SERVICE.G_Now_MS;

    // HMI requests are one-shot. Runtime requests are consumed by archive manager.
    GVL_FILE_ARCHIVE_HMI.G_Write_Event_CSV_Req := FALSE;
    GVL_FILE_ARCHIVE_HMI.G_Write_Trend_CSV_Req := FALSE;
    GVL_FILE_ARCHIVE_HMI.G_Write_BlackBox_CSV_Req := FALSE;
    GVL_FILE_ARCHIVE_HMI.G_Write_Config_Backup_Req := FALSE;
END_IF;

// >>> BULK_SYNC_ANCHOR: PRG_File_Archive_HMI_Applicator <<<
END_PROGRAM
