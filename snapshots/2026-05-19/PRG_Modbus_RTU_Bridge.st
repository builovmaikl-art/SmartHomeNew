PROGRAM PRG_Modbus_RTU_Bridge
VAR
    L_i : INT;
END_VAR

// ======================================================
// MODBUS RTU BRIDGE
// ======================================================
// This PRG transfers requests from the project runtime
// into the RTU bridge contract and applies confirmed responses.
//
// A concrete CODESYS Modbus RTU implementation must:
//   1. Observe G_Request_*
//   2. Execute physical RS485 transaction
//   3. Fill G_Response_*
//
// Safety:
//   - No response is generated internally.
//   - No fake Done is allowed.
// ======================================================

IF NOT GVL_MODBUS_RTU_BRIDGE.G_Bridge_Enabled THEN
    RETURN;
END_IF;

// ======================================================
// EXPORT FIRST ACTIVE REQUEST
// ======================================================
GVL_MODBUS_RTU_BRIDGE.G_Request_Valid := FALSE;

FOR L_i := 1 TO 16 DO

    IF GVL_MODBUS_MASTER.G_Request[L_i].Enable THEN

        GVL_MODBUS_RTU_BRIDGE.G_Request_Valid := TRUE;
        GVL_MODBUS_RTU_BRIDGE.G_Request_Index := L_i;
        GVL_MODBUS_RTU_BRIDGE.G_Request_Slave_ID :=
            GVL_MODBUS_MASTER.G_Request[L_i].Slave_ID;

        GVL_MODBUS_RTU_BRIDGE.G_Request_Function_Code :=
            GVL_MODBUS_MASTER.G_Request[L_i].Function_Code;

        GVL_MODBUS_RTU_BRIDGE.G_Request_Start_Register :=
            GVL_MODBUS_MASTER.G_Request[L_i].Start_Register;

        GVL_MODBUS_RTU_BRIDGE.G_Request_Register_Count :=
            GVL_MODBUS_MASTER.G_Request[L_i].Register_Count;

        GVL_MODBUS_RTU_BRIDGE.G_Request_Write_Value :=
            GVL_MODBUS_MASTER.G_Request[L_i].Write_Value;

        GVL_MODBUS_RTU_BRIDGE.G_Request_Sequence :=
            GVL_MODBUS_MASTER.G_Request[L_i].Sequence;

        GVL_MODBUS_RTU_BRIDGE.G_Request_Timeout_MS :=
            GVL_MODBUS_MASTER.G_Request[L_i].Timeout_MS;

        EXIT;
    END_IF;

END_FOR;

// ======================================================
// APPLY CONFIRMED RESPONSE
// ======================================================
IF GVL_MODBUS_RTU_BRIDGE.G_Response_Done OR
   GVL_MODBUS_RTU_BRIDGE.G_Response_Error THEN

    L_i := GVL_MODBUS_RTU_BRIDGE.G_Request_Index;

    IF (L_i >= 1) AND (L_i <= 16) THEN

        GVL_MODBUS_MASTER.G_Response[L_i].Busy :=
            GVL_MODBUS_RTU_BRIDGE.G_Response_Busy;

        GVL_MODBUS_MASTER.G_Response[L_i].Done :=
            GVL_MODBUS_RTU_BRIDGE.G_Response_Done;

        GVL_MODBUS_MASTER.G_Response[L_i].Error :=
            GVL_MODBUS_RTU_BRIDGE.G_Response_Error;

        GVL_MODBUS_MASTER.G_Response[L_i].Error_Code :=
            GVL_MODBUS_RTU_BRIDGE.G_Response_Error_Code;

        GVL_MODBUS_MASTER.G_Response[L_i].Read_Value :=
            GVL_MODBUS_RTU_BRIDGE.G_Response_Value;

        GVL_MODBUS_MASTER.G_Response[L_i].Last_Sequence :=
            GVL_MODBUS_RTU_BRIDGE.G_Response_Sequence;

        GVL_MODBUS_MASTER.G_Response[L_i].Last_Update_MS :=
            GVL_MODBUS_RTU_BRIDGE.G_Response_Update_MS;

    END_IF;

END_IF;

END_PROGRAM
