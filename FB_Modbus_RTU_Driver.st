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
END_VAR

// ======================================================
// MODBUS RTU DRIVER WRAPPER
// ======================================================
// Controlled boundary for concrete Modbus RTU implementation.
//
// Safety principles:
//   - No fake successful responses.
//   - No fake online state.
//   - Online only after confirmed physical exchange.
//   - Response flags only after real transaction.
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

    END_IF;

END_IF;

// ======================================================
// CONCRETE DRIVER INTEGRATION POINT
// ======================================================
// Real implementation must:
//   1. Open/configure COM port.
//   2. Build RTU frame.
//   3. Perform RS485 exchange.
//   4. Validate CRC.
//   5. Parse response.
//   6. Set Response_* only after confirmed transaction.
//
// IMPORTANT:
//   This wrapper intentionally does NOT synthesize successful responses.
// ======================================================

// Driver online only after real successful exchange.
IF (L_Last_Success_MS > 0) AND
   ((VI_System_Time_MS - L_Last_Success_MS) <
    GVL_CONFIG.G_OpenTherm_Heartbeat_Timeout_MS) THEN

    VO_Driver_Online := TRUE;
    GVL_MODBUS_RTU_BRIDGE.G_Driver_Online := TRUE;

END_IF;

// No active request -> clear busy.
IF NOT L_Request_Active THEN

    GVL_MODBUS_RTU_BRIDGE.G_Response_Busy := FALSE;

    L_Exchange_In_Progress := FALSE;

END_IF;

END_FUNCTION_BLOCK
