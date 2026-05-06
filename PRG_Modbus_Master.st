PROGRAM PRG_Modbus_Master
VAR
    L_i : INT;
END_VAR

// ======================================================
// MODBUS MASTER RUNTIME SCHEDULER
// ======================================================
// This layer intentionally does not depend on a concrete
// CODESYS Modbus library.
//
// Future implementation options:
//   - CODESYS Modbus Serial Master RTU
//   - ModbusFB library
//   - Vendor-specific Modbus drivers
//
// Responsibilities:
//   1. Dispatch queued requests.
//   2. Apply timeout supervision.
//   3. Publish response state.
//   4. Protect transport execution ordering.
//
// Safety rule:
//   Until a concrete Modbus RTU driver is wired here, this PRG must NOT
//   produce fake successful responses.
// ======================================================

IF NOT GVL_CONFIG.G_OpenTherm_Enabled THEN
    GVL_MODBUS_MASTER.G_Master_Online := FALSE;
    GVL_MODBUS_MASTER.G_Master_Error := FALSE;

    FOR L_i := 1 TO 16 DO
        GVL_MODBUS_MASTER.G_Response[L_i].Busy := FALSE;
        GVL_MODBUS_MASTER.G_Response[L_i].Done := FALSE;
        GVL_MODBUS_MASTER.G_Response[L_i].Error := FALSE;
        GVL_MODBUS_MASTER.G_Response[L_i].Error_Code := 0;
    END_FOR;

    RETURN;
END_IF;

// No concrete RTU/TCP implementation is attached yet.
// Keep the master offline instead of simulating a response.
GVL_MODBUS_MASTER.G_Master_Online := FALSE;
GVL_MODBUS_MASTER.G_Master_Error := TRUE;

FOR L_i := 1 TO 16 DO

    IF GVL_MODBUS_MASTER.G_Request[L_i].Enable THEN
        GVL_MODBUS_MASTER.G_Response[L_i].Busy := FALSE;
        GVL_MODBUS_MASTER.G_Response[L_i].Done := FALSE;
        GVL_MODBUS_MASTER.G_Response[L_i].Error := TRUE;
        GVL_MODBUS_MASTER.G_Response[L_i].Error_Code := 16#0001;
        GVL_MODBUS_MASTER.G_Response[L_i].Last_Sequence :=
            GVL_MODBUS_MASTER.G_Request[L_i].Sequence;
        GVL_MODBUS_MASTER.G_Response[L_i].Last_Update_MS :=
            GVL_STATUS.G_System_Time_MS;
    ELSE
        GVL_MODBUS_MASTER.G_Response[L_i].Busy := FALSE;
        GVL_MODBUS_MASTER.G_Response[L_i].Done := FALSE;
    END_IF;

END_FOR;

END_PROGRAM
