FUNCTION_BLOCK FB_Modbus_RTU_Driver
VAR_INPUT
    VI_Enable : BOOL;
    VI_Driver_Attached : BOOL;
    VI_System_Time_MS : UDINT;
END_VAR

VAR_OUTPUT
    VO_Driver_Online : BOOL;
    VO_Driver_Error : BOOL;
    VO_Driver_Error_Code : WORD;
END_VAR

VAR
    L_Request_Active : BOOL;
    L_Last_Sequence : UDINT;
    L_Exchange_In_Progress : BOOL;
    L_Last_Success_MS : UDINT;

    FB_TX_Builder : FB_Modbus_RTU_TX_Builder;
    FB_RX_Parser : FB_Modbus_RTU_RX_Parser;
    FB_Response_Apply : FB_Modbus_Response_Apply;
END_VAR

// ======================================================
// MODBUS RTU DRIVER ORCHESTRATION
// ======================================================
// Responsibilities:
//   1. Detect active request.
//   2. Build TX frame.
//   3. Wait for physical RX frame.
//   4. Validate/parse RX frame.
//   5. Apply validated response.
//
// IMPORTANT:
//   Real serial exchange is still external.
//   Concrete RTU/COM implementation must:
//      - send G_TX_Frame
//      - fill G_RX_Frame
//      - set G_RX_Ready
// ======================================================

VO_Driver_Online := FALSE;
VO_Driver_Error := FALSE;
VO_Driver_Error_Code := 0;

GVL_MODBUS_RTU_BRIDGE.G_Driver_Online := FALSE;
GVL_MODBUS_RTU_BRIDGE.G_Driver_Error := FALSE;
GVL_MODBUS_RTU_BRIDGE.G_Driver_Error_Code := 0;

IF NOT VI_Enable THEN

    GVL_MODBUS_RTU_BRIDGE.G_Response_Busy := FALSE;
    GVL_MODBUS_RTU_BRIDGE.G_Response_Done := FALSE;
    GVL_MODBUS_RTU_BRIDGE.G_Response_Error := FALSE;
    GVL_MODBUS_RTU_BRIDGE.G_Response_Error_Code := 0;

    GVL_MODBUS_RTU_FRAME.G_TX_Ready := FALSE;
    GVL_MODBUS_RTU_FRAME.G_RX_Ready := FALSE;

    L_Exchange_In_Progress := FALSE;

    RETURN;
END_IF;

IF NOT VI_Driver_Attached THEN

    VO_Driver_Error := TRUE;
    VO_Driver_Error_Code := 16#0002;

    GVL_MODBUS_RTU_BRIDGE.G_Driver_Error := TRUE;
    GVL_MODBUS_RTU_BRIDGE.G_Driver_Error_Code := VO_Driver_Error_Code;

    IF GVL_MODBUS_RTU_BRIDGE.G_Request_Valid THEN

        GVL_MODBUS_RTU_BRIDGE.G_Response_Busy := FALSE;
        GVL_MODBUS_RTU_BRIDGE.G_Response_Done := FALSE;
        GVL_MODBUS_RTU_BRIDGE.G_Response_Error := TRUE;
        GVL_MODBUS_RTU_BRIDGE.G_Response_Error_Code := VO_Driver_Error_Code;

        GVL_MODBUS_RTU_BRIDGE.G_Response_Sequence :=
            GVL_MODBUS_RTU_BRIDGE.G_Request_Sequence;

        GVL_MODBUS_RTU_BRIDGE.G_Response_Update_MS :=
            VI_System_Time_MS;

    END_IF;

    L_Exchange_In_Progress := FALSE;

    RETURN;
END_IF;

// ======================================================
// REQUEST DETECTION
// ======================================================
L_Request_Active := GVL_MODBUS_RTU_BRIDGE.G_Request_Valid;

IF L_Request_Active THEN

    IF GVL_MODBUS_RTU_BRIDGE.G_Request_Sequence <> L_Last_Sequence THEN

        L_Last_Sequence :=
            GVL_MODBUS_RTU_BRIDGE.G_Request_Sequence;

        L_Exchange_In_Progress := TRUE;

        GVL_MODBUS_RTU_BRIDGE.G_Response_Busy := TRUE;
        GVL_MODBUS_RTU_BRIDGE.G_Response_Done := FALSE;
        GVL_MODBUS_RTU_BRIDGE.G_Response_Error := FALSE;
        GVL_MODBUS_RTU_BRIDGE.G_Response_Error_Code := 0;

        // ==============================================
        // BUILD TX FRAME
        // ==============================================
        FB_TX_Builder(
            VI_Request_Valid := TRUE,
            VI_Slave_ID := GVL_MODBUS_RTU_BRIDGE.G_Request_Slave_ID,
            VI_Function_Code := GVL_MODBUS_RTU_BRIDGE.G_Request_Function_Code,
            VI_Start_Register := GVL_MODBUS_RTU_BRIDGE.G_Request_Start_Register,
            VI_Register_Count := GVL_MODBUS_RTU_BRIDGE.G_Request_Register_Count,
            VI_Write_Value := GVL_MODBUS_RTU_BRIDGE.G_Request_Write_Value
        );

        IF FB_TX_Builder.VO_Error THEN

            GVL_MODBUS_RTU_BRIDGE.G_Response_Busy := FALSE;
            GVL_MODBUS_RTU_BRIDGE.G_Response_Done := FALSE;
            GVL_MODBUS_RTU_BRIDGE.G_Response_Error := TRUE;
            GVL_MODBUS_RTU_BRIDGE.G_Response_Error_Code :=
                FB_TX_Builder.VO_Error_Code;

            GVL_MODBUS_RTU_BRIDGE.G_Response_Sequence :=
                GVL_MODBUS_RTU_BRIDGE.G_Request_Sequence;

            GVL_MODBUS_RTU_BRIDGE.G_Response_Update_MS :=
                VI_System_Time_MS;

            L_Exchange_In_Progress := FALSE;

            RETURN;

        END_IF;

        GVL_MODBUS_RTU_FRAME.G_TX_Frame :=
            FB_TX_Builder.VO_Frame;

        GVL_MODBUS_RTU_FRAME.G_TX_Ready := TRUE;
        GVL_MODBUS_RTU_FRAME.G_Last_TX_MS := VI_System_Time_MS;

    END_IF;

END_IF;

// ======================================================
// RX FRAME AVAILABLE
// ======================================================
IF L_Exchange_In_Progress AND
   GVL_MODBUS_RTU_FRAME.G_RX_Ready THEN

    // ==================================================
    // PARSE RX FRAME
    // ==================================================
    FB_RX_Parser(
        VI_Frame := GVL_MODBUS_RTU_FRAME.G_RX_Frame,
        VI_Expected_Slave_ID :=
            GVL_MODBUS_RTU_BRIDGE.G_Request_Slave_ID,
        VI_Expected_Function :=
            GVL_MODBUS_RTU_BRIDGE.G_Request_Function_Code
    );

    // ==================================================
    // APPLY RESPONSE
    // ==================================================
    FB_Response_Apply(
        VI_Request_Valid := TRUE,
        VI_Request_Index := GVL_MODBUS_RTU_BRIDGE.G_Request_Index,
        VI_Request_Sequence :=
            GVL_MODBUS_RTU_BRIDGE.G_Request_Sequence,
        VI_Parser_Valid := FB_RX_Parser.VO_Valid,
        VI_Parser_Error := FB_RX_Parser.VO_Error,
        VI_Parser_Error_Code := FB_RX_Parser.VO_Error_Code,
        VI_Register_Count := FB_RX_Parser.VO_Register_Count,
        VI_Register_Value := FB_RX_Parser.VO_Register_Value,
        VI_System_Time_MS := VI_System_Time_MS
    );

    IF FB_Response_Apply.VO_Response_Applied THEN

        L_Last_Success_MS := VI_System_Time_MS;

        GVL_MODBUS_RTU_FRAME.G_RX_Ready := FALSE;

        L_Exchange_In_Progress := FALSE;

    END_IF;

END_IF;

// ======================================================
// DRIVER ONLINE STATE
// ======================================================
IF (L_Last_Success_MS > 0) AND
   ((VI_System_Time_MS - L_Last_Success_MS) <
    GVL_CONFIG.G_OpenTherm_Heartbeat_Timeout_MS) THEN

    VO_Driver_Online := TRUE;

    GVL_MODBUS_RTU_BRIDGE.G_Driver_Online := TRUE;

END_IF;

// ======================================================
// CLEAR IDLE BUSY STATE
// ======================================================
IF NOT L_Request_Active THEN

    GVL_MODBUS_RTU_BRIDGE.G_Response_Busy := FALSE;

    L_Exchange_In_Progress := FALSE;

END_IF;

END_FUNCTION_BLOCK
