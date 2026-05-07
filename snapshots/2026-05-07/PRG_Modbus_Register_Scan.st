PROGRAM PRG_Modbus_Register_Scan
VAR
    L_Register : UINT;
END_VAR

// ======================================================
// SAFE READ-ONLY MODBUS REGISTER SCAN
// ======================================================
// Safety rules:
//   - FC03/FC04 only.
//   - Never write registers.
//   - Manual enable only.
//   - Limited scan range.
// ======================================================

IF NOT GVL_MODBUS_SCAN.G_Scan_Enable THEN
    GVL_MODBUS_SCAN.G_Scan_Active := FALSE;
    GVL_MODBUS_SCAN.G_Scan_Done := FALSE;
    RETURN;
END_IF;

GVL_MODBUS_SCAN.G_Scan_Active := TRUE;
GVL_MODBUS_SCAN.G_Scan_Error := FALSE;

IF GVL_MODBUS_SCAN.G_Current_Register < GVL_MODBUS_SCAN.G_Start_Register THEN
    GVL_MODBUS_SCAN.G_Current_Register :=
        GVL_MODBUS_SCAN.G_Start_Register;
END_IF;

IF GVL_MODBUS_SCAN.G_Current_Register > GVL_MODBUS_SCAN.G_End_Register THEN
    GVL_MODBUS_SCAN.G_Scan_Active := FALSE;
    GVL_MODBUS_SCAN.G_Scan_Done := TRUE;
    RETURN;
END_IF;

L_Register := GVL_MODBUS_SCAN.G_Current_Register;

// ======================================================
// Issue read-only FC03 request
// ======================================================
GVL_MODBUS_MASTER.G_Request[16].Enable := TRUE;
GVL_MODBUS_MASTER.G_Request[16].Slave_ID := GVL_MODBUS_SCAN.G_Slave_ID;
GVL_MODBUS_MASTER.G_Request[16].Function_Code := MB_FC03_READ_HOLDING_REGISTERS;
GVL_MODBUS_MASTER.G_Request[16].Start_Register := L_Register;
GVL_MODBUS_MASTER.G_Request[16].Register_Count := 1;
GVL_MODBUS_MASTER.G_Request[16].Sequence :=
    GVL_MODBUS_MASTER.G_Request[16].Sequence + 1;
GVL_MODBUS_MASTER.G_Request[16].Timeout_MS := 250;

// ======================================================
// Process response
// ======================================================
IF GVL_MODBUS_MASTER.G_Response[16].Done THEN

    GVL_MODBUS_SCAN.G_Found_Register[L_Register] := TRUE;

    GVL_MODBUS_SCAN.G_Found_Value[L_Register] :=
        GVL_MODBUS_MASTER.G_Response[16].Read_Value[1];

    GVL_MODBUS_SCAN.G_Last_Scan_MS := GVL_STATUS.G_System_Time_MS;

    GVL_MODBUS_SCAN.G_Current_Register :=
        GVL_MODBUS_SCAN.G_Current_Register + 1;

ELSIF GVL_MODBUS_MASTER.G_Response[16].Error THEN

    GVL_MODBUS_SCAN.G_Found_Register[L_Register] := FALSE;

    GVL_MODBUS_SCAN.G_Current_Register :=
        GVL_MODBUS_SCAN.G_Current_Register + 1;

END_IF;

END_PROGRAM
