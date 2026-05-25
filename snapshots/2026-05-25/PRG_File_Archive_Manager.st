PROGRAM PRG_File_Archive_Manager
// ==============================================================================
// FILE ARCHIVE MANAGER — deterministic runtime surface for future CSV/file export.
// ==============================================================================
// No direct file, USB or gateway write is implemented here. This program only
// consumes one-shot archive requests, validates the configured target surface and
// publishes a deterministic status/error until concrete CODESYS file libraries
// and port-specific paths are selected.
// ==============================================================================
VAR
    L_Request_Active : BOOL;
    L_Target_Available : BOOL;
END_VAR

// Daily automatic configuration backup scheduler. It publishes the same
// one-shot request as HMI/gateway paths and never writes files directly.
IF GVL_FILE_ARCHIVE.G_Auto_Config_Backup_Enabled THEN
    IF (GVL_TIME_SERVICE.G_Day_Of_Week >= 1) AND
       (GVL_TIME_SERVICE.G_Day_Of_Week <= 7) AND
       (GVL_TIME_SERVICE.G_Time_Of_Day_MS >= GVL_FILE_ARCHIVE.G_Auto_Config_Backup_Time_Of_Day_MS) THEN
        IF GVL_FILE_ARCHIVE.G_Auto_Config_Backup_Last_Day_Of_Week <> GVL_TIME_SERVICE.G_Day_Of_Week THEN
            GVL_FILE_ARCHIVE.G_Write_Config_Backup_Request := TRUE;
            GVL_FILE_ARCHIVE.G_Auto_Config_Backup_Last_Day_Of_Week := GVL_TIME_SERVICE.G_Day_Of_Week;
            GVL_FILE_ARCHIVE.G_Auto_Config_Backup_Last_Request_MS := GVL_TIME_SERVICE.G_Now_MS;
            GVL_FILE_ARCHIVE.G_Auto_Config_Backup_Last_Status_Text := 'Auto config backup request published';
        END_IF;
    END_IF;
END_IF;

L_Request_Active :=
    GVL_FILE_ARCHIVE.G_Write_Event_CSV_Request
    OR GVL_FILE_ARCHIVE.G_Write_Trend_CSV_Request
    OR GVL_FILE_ARCHIVE.G_Write_BlackBox_CSV_Request
    OR GVL_FILE_ARCHIVE.G_Write_Config_Backup_Request;

L_Target_Available := FALSE;
CASE GVL_FILE_ARCHIVE.G_File_Archive_Target_Code OF
    1:
        L_Target_Available := GVL_FILE_ARCHIVE.G_PLC_File_Target_Available;
    2:
        L_Target_Available := GVL_FILE_ARCHIVE.G_USB_Target_Available;
    3:
        L_Target_Available := GVL_FILE_ARCHIVE.G_Gateway_Target_Available;
ELSE
    L_Target_Available := FALSE;
END_CASE;

IF L_Request_Active THEN
    GVL_FILE_ARCHIVE.G_Write_Busy := FALSE;
    GVL_FILE_ARCHIVE.G_Write_Done := FALSE;
    GVL_FILE_ARCHIVE.G_Write_Error := FALSE;
    GVL_FILE_ARCHIVE.G_Last_Error_Code := 0;
    GVL_FILE_ARCHIVE.G_Last_Status_Text := '';
    GVL_FILE_ARCHIVE.G_Last_Write_MS := GVL_TIME_SERVICE.G_Now_MS;

    IF NOT GVL_FILE_ARCHIVE.G_Archive_Interface_Enabled THEN
        GVL_FILE_ARCHIVE.G_Write_Error := TRUE;
        GVL_FILE_ARCHIVE.G_Last_Error_Code := 16#A001;
        GVL_FILE_ARCHIVE.G_Last_Status_Text := 'Archive interface disabled';
    ELSIF NOT GVL_FILE_ARCHIVE.G_CSV_Write_Enabled THEN
        GVL_FILE_ARCHIVE.G_Write_Error := TRUE;
        GVL_FILE_ARCHIVE.G_Last_Error_Code := 16#A002;
        GVL_FILE_ARCHIVE.G_Last_Status_Text := 'CSV archive disabled';
    ELSIF GVL_FILE_ARCHIVE.G_File_Archive_Target_Code = 0 THEN
        GVL_FILE_ARCHIVE.G_Write_Error := TRUE;
        GVL_FILE_ARCHIVE.G_Last_Error_Code := 16#A003;
        GVL_FILE_ARCHIVE.G_Last_Status_Text := 'No archive target selected';
    ELSIF NOT L_Target_Available THEN
        GVL_FILE_ARCHIVE.G_Write_Error := TRUE;
        GVL_FILE_ARCHIVE.G_Last_Error_Code := 16#A004;
        GVL_FILE_ARCHIVE.G_Last_Status_Text := 'Selected archive target unavailable';
    ELSE
        GVL_FILE_ARCHIVE.G_Write_Error := TRUE;
        GVL_FILE_ARCHIVE.G_Last_Error_Code := 16#A005;
        GVL_FILE_ARCHIVE.G_Last_Status_Text := 'Archive backend not connected';
    END_IF;

    // One-shot requests are consumed regardless of the result so HMI/gateway
    // callers receive a stable status instead of repeatedly retriggering.
    GVL_FILE_ARCHIVE.G_Write_Event_CSV_Request := FALSE;
    GVL_FILE_ARCHIVE.G_Write_Trend_CSV_Request := FALSE;
    GVL_FILE_ARCHIVE.G_Write_BlackBox_CSV_Request := FALSE;
    GVL_FILE_ARCHIVE.G_Write_Config_Backup_Request := FALSE;
END_IF;

// >>> BULK_SYNC_ANCHOR: PRG_File_Archive_Manager <<<
END_PROGRAM
