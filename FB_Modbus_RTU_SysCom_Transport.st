FUNCTION_BLOCK FB_Modbus_RTU_SysCom_Transport
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
END_VAR

VAR
    L_i : INT;
END_VAR

// ======================================================
// MODBUS RTU SYSCOM TRANSPORT BOUNDARY
// ======================================================
// Byte-level transport boundary between:
//   - project RTU frame runtime
//   - future concrete SysCom implementation
//
// This FB intentionally does NOT:
//   - open COM ports
//   - call SysCom APIs
//   - generate fake RX frames
//   - generate fake TX done
//
// Concrete SysCom implementation must be connected externally.
// ======================================================

IF NOT VI_Enable THEN

    GVL_MODBUS_SYSCOM_TRANSPORT.G_TX_Request := FALSE;
    GVL_MODBUS_SYSCOM_TRANSPORT.G_TX_Done := FALSE;
    GVL_MODBUS_SYSCOM_TRANSPORT.G_RX_Ready := FALSE;

    RETURN;
END_IF;

// ======================================================
// EXPORT TX FRAME
// ======================================================
IF GVL_MODBUS_RTU_FRAME.G_TX_Ready THEN

    GVL_MODBUS_SYSCOM_TRANSPORT.G_TX_Length :=
        GVL_MODBUS_RTU_FRAME.G_TX_Frame.Length;

    FOR L_i := 0 TO 255 DO
        GVL_MODBUS_SYSCOM_TRANSPORT.G_TX_Buffer[L_i] :=
            GVL_MODBUS_RTU_FRAME.G_TX_Frame.Data[L_i];
    END_FOR;

    GVL_MODBUS_SYSCOM_TRANSPORT.G_TX_Request := TRUE;

    GVL_MODBUS_SYSCOM_TRANSPORT.G_Last_TX_Request_MS :=
        VI_System_Time_MS;

END_IF;

// ======================================================
// CONFIRMED TX DONE
// ======================================================
IF GVL_MODBUS_SYSCOM_TRANSPORT.G_TX_Done THEN

    GVL_MODBUS_RTU_FRAME.G_TX_Ready := FALSE;

    GVL_MODBUS_SYSCOM_TRANSPORT.G_TX_Request := FALSE;

    GVL_MODBUS_SYSCOM_TRANSPORT.G_Last_TX_Done_MS :=
        VI_System_Time_MS;

    GVL_MODBUS_SYSCOM_TRANSPORT.G_Total_TX :=
        GVL_MODBUS_SYSCOM_TRANSPORT.G_Total_TX + 1;

END_IF;

// ======================================================
// IMPORT RX FRAME
// ======================================================
IF GVL_MODBUS_SYSCOM_TRANSPORT.G_RX_Ready THEN

    GVL_MODBUS_RTU_FRAME.G_RX_Frame.Valid := TRUE;
    GVL_MODBUS_RTU_FRAME.G_RX_Frame.Length :=
        GVL_MODBUS_SYSCOM_TRANSPORT.G_RX_Length;

    FOR L_i := 0 TO 255 DO
        GVL_MODBUS_RTU_FRAME.G_RX_Frame.Data[L_i] :=
            GVL_MODBUS_SYSCOM_TRANSPORT.G_RX_Buffer[L_i];
    END_FOR;

    GVL_MODBUS_RTU_FRAME.G_Last_RX_MS :=
        VI_System_Time_MS;

    GVL_MODBUS_RTU_FRAME.G_RX_Ready := TRUE;

    GVL_MODBUS_SYSCOM_TRANSPORT.G_Last_RX_MS :=
        VI_System_Time_MS;

    GVL_MODBUS_SYSCOM_TRANSPORT.G_Total_RX :=
        GVL_MODBUS_SYSCOM_TRANSPORT.G_Total_RX + 1;

    GVL_MODBUS_SYSCOM_TRANSPORT.G_RX_Ready := FALSE;

END_IF;

// ======================================================
// TRANSPORT ERRORS
// ======================================================
IF GVL_MODBUS_SYSCOM_TRANSPORT.G_TX_Error OR
   GVL_MODBUS_SYSCOM_TRANSPORT.G_RX_Error THEN

    GVL_MODBUS_SYSCOM_TRANSPORT.G_Total_Errors :=
        GVL_MODBUS_SYSCOM_TRANSPORT.G_Total_Errors + 1;

END_IF;

END_FUNCTION_BLOCK
