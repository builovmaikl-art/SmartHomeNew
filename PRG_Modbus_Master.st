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
// ======================================================

IF NOT GVL_CONFIG.G_OpenTherm_Enabled THEN
    GVL_MODBUS_MASTER.G_Master_Online := FALSE;
    GVL_MODBUS_MASTER.G_Master_Error := FALSE;
    RETURN;
END_IF;

GVL_MODBUS_MASTER.G_Master_Online := TRUE;
GVL_MODBUS_MASTER.G_Master_Error := FALSE;
GVL_MODBUS_MASTER.G_Last_Transaction_MS := GVL_STATUS.G_System_Time_MS;

FOR L_i := 1 TO 16 DO

    IF GVL_MODBUS_MASTER.G_Request[L_i].Enable THEN

        // ==================================================
        // PLACEHOLDER RUNTIME CONTRACT
        // ==================================================
        // Real Modbus library integration point.
        //
        // The concrete implementation must:
        //   - issue request
        //   - wait for response
        //   - fill response buffer
        //   - set Done/Error
        // ==================================================

        GVL_MODBUS_MASTER.G_Response[L_i].Busy := FALSE;
        GVL_MODBUS_MASTER.G_Response[L_i].Done := TRUE;
        GVL_MODBUS_MASTER.G_Response[L_i].Error := FALSE;
        GVL_MODBUS_MASTER.G_Response[L_i].Last_Sequence :=
            GVL_MODBUS_MASTER.G_Request[L_i].Sequence;

        GVL_MODBUS_MASTER.G_Response[L_i].Last_Update_MS :=
            GVL_STATUS.G_System_Time_MS;

    END_IF;

END_FOR;

END_PROGRAM
