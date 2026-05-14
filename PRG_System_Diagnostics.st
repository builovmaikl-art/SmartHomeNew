PROGRAM PRG_System_Diagnostics
VAR
    fbStateTraceLog : FB_State_Trace_Log;
    fbAdapt : FB_Behavior_Adapt;
    fbSystemDiagnosticsPublisher : FB_System_Diagnostics_Publisher;

    L_Pumps_4 : ARRAY[1..4] OF BOOL;
    L_i : INT;
    L_Last_State_Trace_MS : UDINT;

    L_Hum : REAL;
    L_PrevHum : REAL;
    L_DeltaHum : REAL;
    L_Confidence : REAL;
END_VAR

FOR L_i := 1 TO 4 DO
    L_Pumps_4[L_i] := GVL_HEATING_OUTPUT.DO_Manifold_Pumps[L_i];
END_FOR;

fbStateTraceLog(
    VI_System_Time := GVL_TIME_SERVICE.G_Now_MS,
    VI_Gas_Alarm := GVL_HEALTH_BRIDGE.G_Gas_Detected OR GVL_HEALTH_BRIDGE.G_CO_Alarm_Level,
    VI_Leak_Alarm := GVL_HEALTH_BRIDGE.G_Leak_Detected,
    VI_Pumps := L_Pumps_4,
    VO_Last_Change_Time => L_Last_State_Trace_MS
);

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_ZONES DO

    L_Hum := 0.0;

    IF GVL_BEHAVIOR_ADAPT.G_Prev_Valid[L_i] THEN
        L_PrevHum := GVL_BEHAVIOR_ADAPT.G_Prev_Humidity[L_i];
    ELSE
        L_PrevHum := L_Hum;
    END_IF;

    L_DeltaHum := L_PrevHum - L_Hum;

    IF ABS(L_DeltaHum) < 0.5 THEN
        L_Confidence := 0.2;
    ELSE
        L_Confidence := 1.0;
    END_IF;

    IF GVL_INTENT_BEHAVIOR.I_Request_Ventilation_Boost THEN
        fbAdapt(
            iScenario := REASON_SCENARIO_VENT_BOOST,
            iSuccess := (L_DeltaHum > 5.0),
            iMeasuredValue := L_Hum,
            iZone := L_i,
            iConfidence := L_Confidence
        );
    END_IF;

    GVL_BEHAVIOR_ADAPT.G_Prev_Humidity[L_i] := L_Hum;
    GVL_BEHAVIOR_ADAPT.G_Prev_Valid[L_i] := TRUE;

END_FOR;

IF GVL_INTENT_BEHAVIOR.I_Request_Night_Mode THEN
    fbAdapt(
        iScenario := REASON_SCENARIO_NIGHT,
        iSuccess := TRUE,
        iMeasuredValue := 0.0,
        iZone := 0,
        iConfidence := 1.0
    );
END_IF;


fbSystemDiagnosticsPublisher(
    VI_Enable := TRUE,
    VI_System_Time_MS := GVL_TIME_SERVICE.G_Now_MS,
    VI_Backup_Pump_Out_Of_Service := NOT GVL_CONFIG.G_Backup_Circulation_Pump_In_Service,
    VI_Electric_Heater_Out_Of_Service := NOT GVL_CONFIG.G_Electric_Heater_In_Service,
    VI_Manifold_Pump_Out_Of_Service := NOT GVL_CONFIG.G_Manifold_Pump_In_Service,
    VI_DHW_Heating_Pump_Out_Of_Service := NOT GVL_CONFIG.G_DHW_Heating_Pump_In_Service,
    VI_DHW_Circ_Pump_Out_Of_Service := NOT GVL_CONFIG.G_DHW_Circ_Pump_In_Service,
    VI_User_Access_Level := GVL_COMMAND.CMD_User_Access_Level,
    VI_Dangerous_Action_Pending := GVL_COMMAND.CMD_Dangerous_Action_Request,
    VI_Dangerous_Action_Text := 'Dangerous action confirmation requested',
    VI_Sensor_Fault := GVL_STATE.G_Heating_Sensor_Fault OR GVL_STATE.G_DHW_Sensor_Fault,
    VI_IO_Offline := GVL_STATE.G_Heating_IO_Fault OR GVL_STATE.G_DHW_IO_Fault,
    VI_Subsystem_Degraded := GVL_STATE.G_Heating_Subsystem_Degraded OR GVL_STATE.G_DHW_Subsystem_Degraded,
    VI_Manifold_Pressure_Fault := GVL_HEATING_DIAGNOSTICS.G_Manifold_Pressure_Fault,
    VI_Manifold_Current_Fault := GVL_HEATING_DIAGNOSTICS.G_Manifold_Current_Fault,
    VI_Manifold_Return_Temp_Fault := GVL_HEATING_DIAGNOSTICS.G_Manifold_Return_Temp_Fault
);

GVL_System_Diagnostics_Publication.G_System_Diagnostics :=
    fbSystemDiagnosticsPublisher.VO_Diagnostics;

GVL_System_Diagnostics_Publication.G_System_Diagnostics_Publication_Valid :=
    fbSystemDiagnosticsPublisher.VO_Publication_Valid;

GVL_System_Diagnostics_Publication.G_System_Diagnostics_Status_Code :=
    fbSystemDiagnosticsPublisher.VO_Status_Code;

GVL_System_Diagnostics_Publication.G_System_Diagnostics_Status_Text :=
    fbSystemDiagnosticsPublisher.VO_Status_Text;

END_PROGRAM
