PROGRAM PRG_Input_Processing
VAR
    L_i : INT;
END_VAR

// This layer is a normalized read-model between PRG_IO_Read/GVL_STATE and higher-level logic.
// It must not write to IO, commands, domain outputs or user intent.

GVL_INPUT.IN_Last_Update_MS := GVL_TIME_SERVICE.G_Now_MS;
GVL_INPUT.IN_Source_Valid := GVL_STATUS.G_Is_Active_PLC;

GVL_INPUT.IN_Input_Degraded := GVL_STATUS.G_Diagnostics.Subsystem_Degraded;
GVL_INPUT.IN_Sensor_Fault := GVL_STATUS.G_Diagnostics.Sensor_Fault;

GVL_INPUT.IN_Outdoor_Temp := GVL_STATE.G_Outdoor_Temp;
GVL_INPUT.IN_Preheat_Request := GVL_STATE.G_Preheat_Request;
GVL_INPUT.IN_Freeze_Request := GVL_STATE.G_Freeze_Request;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_ZONES DO
    GVL_INPUT.IN_Room_Temps[L_i] := GVL_STATE.G_Room_Temps[L_i];
    GVL_INPUT.IN_Floor_Temps[L_i] := GVL_STATE.G_Floor_Temps[L_i];
    GVL_INPUT.IN_Room_Hum[L_i] := GVL_STATE.G_Room_Hum[L_i];
    GVL_INPUT.IN_Room_CO2[L_i] := GVL_STATE.G_Room_CO2[L_i];
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_FLOOD_SENSORS DO
    GVL_INPUT.IN_Water_Sensors[L_i] := GVL_STATE.G_Water_Sensors[L_i];
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SMOKE_SENSORS DO
    GVL_INPUT.IN_Smoke_Sensors[L_i] := GVL_STATE.G_Smoke_Sensors[L_i];
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_METHANE_SENSORS DO
    GVL_INPUT.IN_Methane_Sensors[L_i] := GVL_STATE.G_Methane_Sensors[L_i];
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_CO_SENSORS DO
    GVL_INPUT.IN_CO_Sensors[L_i] := GVL_STATE.G_CO_Sensors[L_i];
END_FOR;

// >>> BULK_SYNC_ANCHOR: PRG_Input_Processing <<<
