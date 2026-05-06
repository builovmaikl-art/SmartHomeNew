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
    L_i : INT;
END_VAR

// ======================================================
// MODBUS RTU DRIVER WRAPPER
// ======================================================
// This FB is the controlled boundary for a concrete CODESYS/vendor
// Modbus Serial Master implementation.
//
// It intentionally does NOT generate successful responses by itself.
// A concrete driver must be connected inside this FB or alongside this
// FB and must fill GVL_MODBUS_RTU_BRIDGE.G_Response_* only after a real
// RS485 transaction.
// ======================================================

VO_Driver_Online := FALSE;
VO_Driver_Error := FALSE;
VO_Driver_Error_Code := 0;

IF NOT VI_Enable THEN
    GVL_MODBUS_RTU_BRIDGE.G_Driver_Online := FALSE;
    GVL_MODBUS_RTU_BRIDGE.G_Driver_Error := FALSE;
    GVL_MODBUS_RTU_BRIDGE.G_Driver_Error_Code := 0;
    GVL_MODBUS_RTU_BRIDGE.G_Response_Busy := FALSE;
    GVL_MODBUS_RTU_BRIDGE.G_Response_Done := FALSE;
    GVL_MODBUS_RTU_BRIDGE.G_Response_Error := FALSE;
    GVL_MODBUS_RTU_BRIDGE.G_Response_Error_Code := 0;
    RETURN;
END_IF;

IF NOT VI_Driver_Attached THEN
    VO_Driver_Online := FALSE;
    VO_Driver_Error := TRUE;
    VO_Driver_Error_Code := 16#0002;

    GVL_MODBUS_RTU_BRIDGE.G_Driver_Online := FALSE;
    GVL_MODBUS_RTU_BRIDGE.G_Driver_Error := TRUE;
    GVL_MODBUS_RTU_BRIDGE.G_Driver_Error_Code := VO_Driver_Error_Code;

    IF GVL_MODBUS_RTU_BRIDGE.G_Request_Valid THEN
        GVL_MODBUS_RTU_BRIDGE.G_Response_Busy := FALSE;
        GVL_MODBUS_RTU_BRIDGE.G_Response_Done := FALSE;
        GVL_MODBUS_RTU_BRIDGE.G_Response_Error := TRUE;
        GVL_MODBUS_RTU_BRIDGE.G_Response_Error_Code := VO_Driver_Error_Code;
        GVL_MODBUS_RTU_BRIDGE.G_Response_Sequence :=
            GVL_MODBUS_RTU_BRIDGE.G_Request_Sequence;
        GVL_MODBUS_RTU_BRIDGE.G_Response_Update_MS := VI_System_Time_MS;
    END_IF;

    RETURN;
END_IF;

// ======================================================
// CONCRETE DRIVER INTEGRATION POINT
// ======================================================
// Attach CODESYS Modbus Serial Master / vendor RTU driver here.
// The concrete implementation must use:
//   G_Request_Slave_ID
//   G_Request_Function_Code
//   G_Request_Start_Register
//   G_Request_Register_Count
//   G_Request_Write_Value
//
// and must set only after real transaction:
//   G_Response_Busy
//   G_Response_Done
//   G_Response_Error
//   G_Response_Error_Code
//   G_Response_Value
//   G_Response_Sequence
//   G_Response_Update_MS
// ======================================================

VO_Driver_Online := TRUE;
VO_Driver_Error := FALSE;
VO_Driver_Error_Code := 0;

GVL_MODBUS_RTU_BRIDGE.G_Driver_Online := TRUE;
GVL_MODBUS_RTU_BRIDGE.G_Driver_Error := FALSE;
GVL_MODBUS_RTU_BRIDGE.G_Driver_Error_Code := 0;

IF NOT GVL_MODBUS_RTU_BRIDGE.G_Request_Valid THEN
    GVL_MODBUS_RTU_BRIDGE.G_Response_Busy := FALSE;
    GVL_MODBUS_RTU_BRIDGE.G_Response_Done := FALSE;
    GVL_MODBUS_RTU_BRIDGE.G_Response_Error := FALSE;
    GVL_MODBUS_RTU_BRIDGE.G_Response_Error_Code := 0;
END_IF;

END_FUNCTION_BLOCK
