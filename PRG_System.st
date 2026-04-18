PROGRAM PRG_System
VAR

// === SENSOR PROCESSING (SHADOW) ===
L_CO_Raw_Word := REAL_TO_WORD(GVL_STATE.G_CO_Sensors[1]);
GVL_Sensor_Shadow.G_CO_Raw_Word := L_CO_Raw_Word;

fbSensorCO(
    VI_Raw_Value := L_CO_Raw_Word,
    VI_Sensor_Type := 0,
    VI_Min_Scale := 0.0,
    VI_Max_Scale := 100.0,
    VI_Offset := 0.0,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

L_CO_Processed := fbSensorCO.VO_Value;

fbCalibCO(
    VI_Raw_Value := L_CO_Processed,
    VI_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[1]
);

GVL_Sensor_Shadow.G_CO_Processed := L_CO_Processed;
GVL_Sensor_Shadow.G_CO_Calibrated := fbCalibCO.VO_Calibrated_Value;
GVL_Sensor_Shadow.G_CO_Error := fbSensorCO.VO_Error;
GVL_Sensor_Shadow.G_CO_Diag_Code := fbSensorCO.VO_Diag_Code;

// === LIFETIME UPDATE ===

// pump (временно FALSE — до реального сигнала)
fbLifetimePump(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Device_Active  := GVL_PERSISTENT.P_DHW_Heating_Active,
    VI_Device_ID      := GVL_Lifetime.G_Device_Pump,
    VI_Nominal_Hours  := GVL_Lifetime.G_Pump_Nominal_Hours,
    VIO_Status        := GVL_Lifetime.G_Status[1]
);

// fan (временно FALSE — до реального сигнала)
fbLifetimeFan(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Device_Active  := (
        GVL_STATE.G_Supply_Fans[1] > 0 OR
        GVL_STATE.G_Exhaust_Fans[1] > 0
    ),
    VI_Device_ID      := GVL_Lifetime.G_Device_Fan,
    VI_Nominal_Hours  := GVL_Lifetime.G_Fan_Nominal_Hours,
    VIO_Status        := GVL_Lifetime.G_Status[2]
);


// === LIFETIME HMI ACTIVE VIEW ===
IF GVL_Lifetime.G_Active_Device_Index < 1 THEN
    GVL_Lifetime.G_Active_Device_Index := 1;
ELSIF GVL_Lifetime.G_Active_Device_Index > 4 THEN
    GVL_Lifetime.G_Active_Device_Index := 4;
END_IF;

GVL_Lifetime.G_Active_Runtime_Hours := GVL_Lifetime.G_Status[GVL_Lifetime.G_Active_Device_Index].runtime_hours;
GVL_Lifetime.G_Active_Remaining_Hours := GVL_Lifetime.G_Status[GVL_Lifetime.G_Active_Device_Index].remaining_hours;
GVL_Lifetime.G_Active_Remaining_Percent := GVL_Lifetime.G_Status[GVL_Lifetime.G_Active_Device_Index].remaining_percent;
GVL_Lifetime.G_Active_Maintenance_Required := GVL_Lifetime.G_Status[GVL_Lifetime.G_Active_Device_Index].maintenance_required;
GVL_Lifetime.G_Active_Label := GVL_Lifetime.G_Device_Labels[GVL_Lifetime.G_Active_Device_Index];

// === LIFETIME HEALTH SUMMARY ===
GVL_Lifetime.G_Any_Maintenance_Required :=
    GVL_Lifetime.G_Status[1].maintenance_required OR
    GVL_Lifetime.G_Status[2].maintenance_required OR
    GVL_Lifetime.G_Status[3].maintenance_required OR
    GVL_Lifetime.G_Status[4].maintenance_required;

GVL_Lifetime.G_Maintenance_Warning :=
    (GVL_Lifetime.G_Status[1].remaining_percent <= 20) OR
    (GVL_Lifetime.G_Status[2].remaining_percent <= 20) OR
    (GVL_Lifetime.G_Status[3].remaining_percent <= 20) OR
    (GVL_Lifetime.G_Status[4].remaining_percent <= 20);

GVL_Lifetime.G_Maintenance_Critical :=
    (GVL_Lifetime.G_Status[1].remaining_percent <= 5) OR
    (GVL_Lifetime.G_Status[2].remaining_percent <= 5) OR
    (GVL_Lifetime.G_Status[3].remaining_percent <= 5) OR
    (GVL_Lifetime.G_Status[4].remaining_percent <= 5);

// === TREND → HISTORY WRITE (RATE-LIMITED SAFE MVP) ===
L_Trend_Write := (L_Trend_Data.record_count > 0);
L_Trend_Write_Allowed := FALSE;

IF L_Trend_Write AND NOT L_Trend_Write_Prev THEN
    IF (L_Trend_Last_Write_MS = 0) OR
       ((GVL_STATUS.G_System_Time_MS - L_Trend_Last_Write_MS) >= GVL_CONSTANTS.C_MS_IN_HOUR) THEN
        IF ABS(L_Trend_Avg - L_Trend_Last_Written_Avg) >= 0.5 THEN
            L_Trend_Write_Allowed := TRUE;
        END_IF;
    END_IF;

    IF L_Trend_Write_Allowed THEN
        L_Trend_Event.event_code := 1001;
        L_Trend_Event.event_value := L_Trend_Avg;
        L_Trend_Event.zone_id := 0;
        L_Trend_Event.operator_id := '';
        L_History_Write_Event := TRUE;
        L_History_Event := L_Trend_Event;

        L_Trend_Last_Write_MS := GVL_STATUS.G_System_Time_MS;
        L_Trend_Last_Written_Avg := L_Trend_Avg;
    END_IF;
END_IF;

L_Trend_Write_Prev := L_Trend_Write;

// >>> BULK_SYNC_ANCHOR: PRG_System <<<

// === EVENT LOGGING: FAULTS ===

// WATCHDOG
IF fbWatchdog.VO_Watchdog_Fault AND NOT L_Watchdog_Fault_Prev THEN
    fbLogEvent(
        VI_Event_Type := 11,
        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
        VI_Param1 := 1,
        VI_Param2 := 1
    );
END_IF;

IF NOT fbWatchdog.VO_Watchdog_Fault AND L_Watchdog_Fault_Prev THEN
    fbLogEvent(
        VI_Event_Type := 12,
        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
        VI_Param1 := 1,
        VI_Param2 := 0
    );
END_IF;

L_Watchdog_Fault_Prev := fbWatchdog.VO_Watchdog_Fault;

// IO
IF fbSystemHealth.VO_IO_Fault AND NOT L_IO_Fault_Prev THEN
    fbLogEvent(
        VI_Event_Type := 2,
        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
        VI_Param1 := 1,
        VI_Param2 := 1
    );
END_IF;

IF NOT fbSystemHealth.VO_IO_Fault AND L_IO_Fault_Prev THEN
    fbLogEvent(
        VI_Event_Type := 3,
        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
        VI_Param1 := 1,
        VI_Param2 := 0
    );
END_IF;

L_IO_Fault_Prev := fbSystemHealth.VO_IO_Fault;

// === EVENT LOGGING: MODE CHANGE ===
IF GVL_STATE.G_System_Mode <> L_Mode_Prev THEN
    fbLogEvent(
        VI_Event_Type := 4,
        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
        VI_Param1 := TO_UDINT(L_Mode_Prev),
        VI_Param2 := TO_UDINT(GVL_STATE.G_System_Mode)
    );
END_IF;

L_Mode_Prev := GVL_STATE.G_System_Mode;
