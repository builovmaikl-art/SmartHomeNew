FUNCTION_BLOCK FB_Modbus_Response_Apply
VAR_INPUT
    VI_Request_Valid : BOOL;
    VI_Request_Index : INT;
    VI_Request_Sequence : UDINT;
    VI_Parser_Valid : BOOL;
    VI_Parser_Error : BOOL;
    VI_Parser_Error_Code : WORD;
    VI_Register_Count : UINT;
    VI_Register_Value : ARRAY[1..32] OF WORD;
    VI_System_Time_MS : UDINT;
END_VAR

VAR_OUTPUT
    VO_Response_Applied : BOOL;
END_VAR

VAR
    L_i : UINT;
END_VAR

// ======================================================
// MODBUS RESPONSE APPLY LAYER
// ======================================================
// Transfers validated parser result into bridge/master response.
//
// Safety principles:
//   - Only validated parser result may produce Done.
//   - Parser error produces Error response.
//   - No synthetic successful response.
// ======================================================

VO_Response_Applied := FALSE;

IF NOT VI_Request_Valid THEN
    RETURN;
END_IF;

IF (VI_Request_Index < 1) OR (VI_Request_Index > 16) THEN
    RETURN;
END_IF;

// ======================================================
// PARSER ERROR
// ======================================================
IF VI_Parser_Error THEN

    GVL_MODBUS_RTU_BRIDGE.G_Response_Busy := FALSE;
    GVL_MODBUS_RTU_BRIDGE.G_Response_Done := FALSE;
    GVL_MODBUS_RTU_BRIDGE.G_Response_Error := TRUE;
    GVL_MODBUS_RTU_BRIDGE.G_Response_Error_Code := VI_Parser_Error_Code;
    GVL_MODBUS_RTU_BRIDGE.G_Response_Sequence := VI_Request_Sequence;
    GVL_MODBUS_RTU_BRIDGE.G_Response_Update_MS := VI_System_Time_MS;

    VO_Response_Applied := TRUE;

    RETURN;
END_IF;

// ======================================================
// VALID PARSED RESPONSE
// ======================================================
IF VI_Parser_Valid THEN

    FOR L_i := 1 TO 32 DO
        GVL_MODBUS_RTU_BRIDGE.G_Response_Value[L_i] := 0;
    END_FOR;

    FOR L_i := 1 TO VI_Register_Count DO
        GVL_MODBUS_RTU_BRIDGE.G_Response_Value[L_i] :=
            VI_Register_Value[L_i];
    END_FOR;

    GVL_MODBUS_RTU_BRIDGE.G_Response_Busy := FALSE;
    GVL_MODBUS_RTU_BRIDGE.G_Response_Done := TRUE;
    GVL_MODBUS_RTU_BRIDGE.G_Response_Error := FALSE;
    GVL_MODBUS_RTU_BRIDGE.G_Response_Error_Code := 0;
    GVL_MODBUS_RTU_BRIDGE.G_Response_Sequence := VI_Request_Sequence;
    GVL_MODBUS_RTU_BRIDGE.G_Response_Update_MS := VI_System_Time_MS;

    VO_Response_Applied := TRUE;

END_IF;

END_FUNCTION_BLOCK
