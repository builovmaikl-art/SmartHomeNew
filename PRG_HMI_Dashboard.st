PROGRAM PRG_HMI_Dashboard
VAR
    L_i : INT;
    L_Archive_Target_Available : BOOL;
END_VAR

// ======================================================
// HEATING CONFIDENCE
// ======================================================
GVL_HMI.G_HMI_Heating_Confidence := GVL_STATE.G_Heating_Confidence;
GVL_HMI.G_HMI_Heating_Confidence_Percent := REAL_TO_INT(GVL_STATE.G_Heating_Confidence * 100.0);

// ======================================================
// HEATING ROOT CAUSE
// ======================================================
GVL_HMI.G_HMI_Heating_Reason_Code := GVL_STATE.G_Heating_Confidence_Reason_Code;
GVL_HMI.G_HMI_Heating_Status_Text := GVL_STATE.G_Heating_Confidence_Reason_Text;

// ======================================================
// HEATING STATUS LEVEL
// ======================================================
IF GVL_STATE.G_Heating_Confidence > 0.8 THEN
    GVL_HMI.G_HMI_Heating_Status_Level := 0;
ELSIF GVL_STATE.G_Heating_Confidence > 0.5 THEN
    GVL_HMI.G_HMI_Heating_Status_Level := 1;
ELSE
    GVL_HMI.G_HMI_Heating_Status_Level := 2;
END_IF;

// ======================================================
// CASCADE SEMANTIC STATE
// ======================================================
GVL_HMI.G_HMI_Heating_Cascade_Available :=
    GVL_STATE.G_Heating_Cascade_Available;

GVL_HMI.G_HMI_Heating_Cascade_Degraded :=
    GVL_STATE.G_Heating_Cascade_Degraded;

GVL_HMI.G_HMI_Heating_Cascade_Partial_Capacity :=
    GVL_STATE.G_Heating_Cascade_Partial_Capacity;

GVL_HMI.G_HMI_Heating_Cascade_No_Flame :=
    GVL_STATE.G_Heating_Cascade_No_Flame;

GVL_HMI.G_HMI_Heating_Cascade_Transport_Degraded :=
    GVL_STATE.G_Heating_Cascade_Transport_Degraded;

GVL_HMI.G_HMI_Heating_Cascade_Ignition_Timeout :=
    GVL_STATE.G_Heating_Cascade_Ignition_Timeout;

GVL_HMI.G_HMI_Heating_Cascade_Active_Boilers :=
    GVL_STATE.G_Heating_Cascade_Active_Boilers;

GVL_HMI.G_HMI_Heating_Cascade_Available_Boilers :=
    GVL_STATE.G_Heating_Cascade_Available_Boilers;

// ======================================================
// OPENTHERM SEMANTIC STATE
// ======================================================
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BOILERS DO

    GVL_HMI.G_HMI_Boiler_OT_Online[L_i] :=
        GVL_STATE.G_Boiler_OT_Online[L_i];

    GVL_HMI.G_HMI_Boiler_OT_Command_Ack[L_i] :=
        GVL_STATE.G_Boiler_OT_Command_Ack[L_i];

    GVL_HMI.G_HMI_Boiler_OT_Command_Timeout[L_i] :=
        GVL_STATE.G_Boiler_OT_Command_Timeout[L_i];

    GVL_HMI.G_HMI_Boiler_OT_Heartbeat_Timeout[L_i] :=
        GVL_STATE.G_Boiler_OT_Heartbeat_Timeout[L_i];

    GVL_HMI.G_HMI_Boiler_OT_Adapter_Error[L_i] :=
        GVL_STATE.G_Boiler_OT_Adapter_Error[L_i];

    GVL_HMI.G_HMI_Boiler_OT_Heartbeat_Age_MS[L_i] :=
        GVL_STATE.G_Boiler_OT_Heartbeat_Age_MS[L_i];

    GVL_HMI.G_HMI_Boiler_OT_Command_Age_MS[L_i] :=
        GVL_STATE.G_Boiler_OT_Command_Age_MS[L_i];

    GVL_HMI.G_HMI_Boiler_OT_Adapter_State[L_i] :=
        GVL_STATE.G_Boiler_OT_Adapter_State[L_i];

    GVL_HMI.G_HMI_Boiler_OT_Error_State[L_i] :=
        GVL_STATE.G_Boiler_OT_Error_State[L_i];

END_FOR;

// ======================================================
// PREDICTIVE FLAGS
// ======================================================
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    GVL_HMI.G_HMI_Heating_Predictive_Pressure_Drop[L_i] :=
        GVL_STATE.G_Predictive_Pump_Pressure_Drop[L_i];

    GVL_HMI.G_HMI_Heating_Predictive_Current_Rise[L_i] :=
        GVL_STATE.G_Predictive_Pump_Current_Rise[L_i];
END_FOR;

// ======================================================
// FILE / ARCHIVE STATUS (READ-ONLY DASHBOARD)
// ======================================================
L_Archive_Target_Available := FALSE;
CASE GVL_FILE_ARCHIVE.G_File_Archive_Target_Code OF
    1:
        L_Archive_Target_Available := GVL_FILE_ARCHIVE.G_PLC_File_Target_Available;
    2:
        L_Archive_Target_Available := GVL_FILE_ARCHIVE.G_USB_Target_Available;
    3:
        L_Archive_Target_Available := GVL_FILE_ARCHIVE.G_Gateway_Target_Available;
ELSE
    L_Archive_Target_Available := FALSE;
END_CASE;

GVL_HMI.G_HMI_File_Archive_Interface_Enabled := GVL_FILE_ARCHIVE.G_Archive_Interface_Enabled;
GVL_HMI.G_HMI_File_Archive_CSV_Enabled := GVL_FILE_ARCHIVE.G_CSV_Write_Enabled;
GVL_HMI.G_HMI_File_Archive_Target_Code := GVL_FILE_ARCHIVE.G_File_Archive_Target_Code;
GVL_HMI.G_HMI_File_Archive_Target_Available := L_Archive_Target_Available;
GVL_HMI.G_HMI_File_Archive_Write_Busy := GVL_FILE_ARCHIVE.G_Write_Busy;
GVL_HMI.G_HMI_File_Archive_Write_Done := GVL_FILE_ARCHIVE.G_Write_Done;
GVL_HMI.G_HMI_File_Archive_Write_Error := GVL_FILE_ARCHIVE.G_Write_Error;
GVL_HMI.G_HMI_File_Archive_Last_Error_Code := GVL_FILE_ARCHIVE.G_Last_Error_Code;
GVL_HMI.G_HMI_File_Archive_Last_Status_Text := GVL_FILE_ARCHIVE.G_Last_Status_Text;
GVL_HMI.G_HMI_File_Archive_Last_Write_MS := GVL_FILE_ARCHIVE.G_Last_Write_MS;

IF GVL_FILE_ARCHIVE.G_Write_Error THEN
    GVL_HMI.G_HMI_File_Archive_Status_Level := 2;
ELSIF GVL_FILE_ARCHIVE.G_Write_Busy THEN
    GVL_HMI.G_HMI_File_Archive_Status_Level := 1;
ELSIF GVL_FILE_ARCHIVE.G_Archive_Interface_Enabled AND GVL_FILE_ARCHIVE.G_CSV_Write_Enabled AND L_Archive_Target_Available THEN
    GVL_HMI.G_HMI_File_Archive_Status_Level := 0;
ELSE
    GVL_HMI.G_HMI_File_Archive_Status_Level := 1;
END_IF;

END_PROGRAM
