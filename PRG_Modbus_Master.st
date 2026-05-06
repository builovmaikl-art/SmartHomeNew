PROGRAM PRG_Modbus_Master
VAR
    L_i : INT;
    L_Elapsed_MS : UDINT;
END_VAR

// ======================================================
// MODBUS MASTER RUNTIME SCHEDULER
// ======================================================
// Library-independent Modbus master scheduler.
//
// Responsibilities:
//   1. Select active request.
//   2. Maintain single active transaction.
//   3. Track timeout/retry state.
//   4. Publish diagnostics/statistics.
//
// Safety:
//   - No fake successful response.
//   - No parallel write collisions.
//   - Timeout must terminate transaction.
// ======================================================

IF NOT GVL_CONFIG.G_OpenTherm_Enabled THEN

    GVL_MODBUS_MASTER.G_Master_Online := FALSE;
    GVL_MODBUS_MASTER.G_Master_Error := FALSE;

    GVL_MODBUS_MASTER.G_Active := FALSE;
    GVL_MODBUS_MASTER.G_Active_Index := 0;
    GVL_MODBUS_MASTER.G_Active_Sequence := 0;
    GVL_MODBUS_MASTER.G_Active_Start_MS := 0;
    GVL_MODBUS_MASTER.G_Active_Retry_Count := 0;

    FOR L_i := 1 TO 16 DO
        GVL_MODBUS_MASTER.G_Response[L_i].Busy := FALSE;
        GVL_MODBUS_MASTER.G_Response[L_i].Done := FALSE;
        GVL_MODBUS_MASTER.G_Response[L_i].Error := FALSE;
        GVL_MODBUS_MASTER.G_Response[L_i].Error_Code := 0;
    END_FOR;

    RETURN;
END_IF;

GVL_MODBUS_MASTER.G_Master_Online :=
    GVL_MODBUS_RTU_BRIDGE.G_Driver_Online;

GVL_MODBUS_MASTER.G_Master_Error :=
    GVL_MODBUS_RTU_BRIDGE.G_Driver_Error;

// ======================================================
// START NEW TRANSACTION
// ======================================================
IF NOT GVL_MODBUS_MASTER.G_Active THEN

    FOR L_i := 1 TO 16 DO

        IF GVL_MODBUS_MASTER.G_Request[L_i].Enable THEN

            GVL_MODBUS_MASTER.G_Active := TRUE;
            GVL_MODBUS_MASTER.G_Active_Index := L_i;
            GVL_MODBUS_MASTER.G_Active_Sequence :=
                GVL_MODBUS_MASTER.G_Request[L_i].Sequence;

            GVL_MODBUS_MASTER.G_Active_Start_MS :=
                GVL_STATUS.G_System_Time_MS;

            GVL_MODBUS_MASTER.G_Active_Retry_Count := 0;

            GVL_MODBUS_MASTER.G_Response[L_i].Busy := TRUE;
            GVL_MODBUS_MASTER.G_Response[L_i].Done := FALSE;
            GVL_MODBUS_MASTER.G_Response[L_i].Error := FALSE;
            GVL_MODBUS_MASTER.G_Response[L_i].Error_Code := 0;

            EXIT;

        END_IF;

    END_FOR;

END_IF;

// ======================================================
// ACTIVE TRANSACTION SUPERVISION
// ======================================================
IF GVL_MODBUS_MASTER.G_Active THEN

    L_i := GVL_MODBUS_MASTER.G_Active_Index;

    L_Elapsed_MS :=
        GVL_STATUS.G_System_Time_MS -
        GVL_MODBUS_MASTER.G_Active_Start_MS;

    // ==================================================
    // CONFIRMED RESPONSE
    // ==================================================
    IF GVL_MODBUS_MASTER.G_Response[L_i].Done OR
       GVL_MODBUS_MASTER.G_Response[L_i].Error THEN

        GVL_MODBUS_MASTER.G_Response[L_i].Busy := FALSE;

        GVL_MODBUS_MASTER.G_Active := FALSE;
        GVL_MODBUS_MASTER.G_Last_Transaction_MS :=
            GVL_STATUS.G_System_Time_MS;

        GVL_MODBUS_MASTER.G_Total_Transactions :=
            GVL_MODBUS_MASTER.G_Total_Transactions + 1;

        IF GVL_MODBUS_MASTER.G_Response[L_i].Error THEN
            GVL_MODBUS_MASTER.G_Total_Errors :=
                GVL_MODBUS_MASTER.G_Total_Errors + 1;
        END_IF;

    // ==================================================
    // TIMEOUT SUPERVISION
    // ==================================================
    ELSIF L_Elapsed_MS > GVL_MODBUS_MASTER.G_Request[L_i].Timeout_MS THEN

        GVL_MODBUS_MASTER.G_Active_Retry_Count :=
            GVL_MODBUS_MASTER.G_Active_Retry_Count + 1;

        IF GVL_MODBUS_MASTER.G_Active_Retry_Count >
           GVL_CONFIG.G_Modbus_RTU_Config.Retry_Count THEN

            GVL_MODBUS_MASTER.G_Response[L_i].Busy := FALSE;
            GVL_MODBUS_MASTER.G_Response[L_i].Done := FALSE;
            GVL_MODBUS_MASTER.G_Response[L_i].Error := TRUE;
            GVL_MODBUS_MASTER.G_Response[L_i].Error_Code := 16#0003;

            GVL_MODBUS_MASTER.G_Response[L_i].Last_Sequence :=
                GVL_MODBUS_MASTER.G_Active_Sequence;

            GVL_MODBUS_MASTER.G_Response[L_i].Last_Update_MS :=
                GVL_STATUS.G_System_Time_MS;

            GVL_MODBUS_MASTER.G_Active := FALSE;

            GVL_MODBUS_MASTER.G_Total_Timeouts :=
                GVL_MODBUS_MASTER.G_Total_Timeouts + 1;

            GVL_MODBUS_MASTER.G_Total_Errors :=
                GVL_MODBUS_MASTER.G_Total_Errors + 1;

        ELSE

            // restart timeout window for retry
            GVL_MODBUS_MASTER.G_Active_Start_MS :=
                GVL_STATUS.G_System_Time_MS;

        END_IF;

    END_IF;

END_IF;

END_PROGRAM
