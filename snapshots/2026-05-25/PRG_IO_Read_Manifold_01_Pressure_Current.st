PROGRAM PRG_IO_Read_Manifold_01_Pressure_Current
VAR
    L_i : INT;
    L_Manifold_Pressure_Raw : WORD;
    L_Manifold_Current_Raw : WORD;

    fbDiagEventManager : FB_Diagnostics_Event_Manager;
    fbAnalog_Manifold_Pressure : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF FB_Sensor_Analog_Processing;
    fbAnalog_Manifold_Current : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF FB_Sensor_Analog_Processing;
END_VAR

GVL_STATUS.G_Diagnostics.Manifold_Pressure_Fault_Active := FALSE;
GVL_STATUS.G_Diagnostics.Manifold_Pressure_First_Fault_Index := 0;
GVL_STATUS.G_Diagnostics.Manifold_Current_Fault_Active := FALSE;
GVL_STATUS.G_Diagnostics.Manifold_Current_First_Fault_Index := 0;
GVL_STATUS.G_Diagnostics.Manifold_Pressure_Fault_Text := '';
GVL_STATUS.G_Diagnostics.Manifold_Current_Fault_Text := '';

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    IF GVL_IO.AI_Manifold_Pressures[L_i] < 0 THEN
        L_Manifold_Pressure_Raw := 0;
    ELSE
        L_Manifold_Pressure_Raw := INT_TO_WORD(GVL_IO.AI_Manifold_Pressures[L_i]);
    END_IF;

    IF GVL_IO.AI_Manifold_Currents[L_i] < 0 THEN
        L_Manifold_Current_Raw := 0;
    ELSE
        L_Manifold_Current_Raw := INT_TO_WORD(GVL_IO.AI_Manifold_Currents[L_i]);
    END_IF;

    fbAnalog_Manifold_Pressure[L_i](
        VI_Raw_Value := L_Manifold_Pressure_Raw,
        VI_Sensor_Type := 0,
        VI_Min_Scale := 0.0,
        VI_Max_Scale := 10.0,
        VI_Offset := 0.0,
        VI_Multiplier := 1.0,
        VI_Filter_Time_MS := GVL_CONSTANTS.C_MS_IN_SECOND,
        VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
        VI_Fallback_Mode := 0,
        VI_Default_Value := 0.0
    );
    GVL_STATE.G_Manifold_Pressures[L_i] := fbAnalog_Manifold_Pressure[L_i].VO_Value;
    GVL_STATUS.G_Diagnostics.Manifold_Pressure_Fault[L_i] := fbAnalog_Manifold_Pressure[L_i].VO_Error;
    GVL_STATUS.G_Diagnostics.Manifold_Pressure_Diag_Code[L_i] := fbAnalog_Manifold_Pressure[L_i].VO_Diag_Code;

    fbDiagEventManager(
        VI_Code := GVL_CONFIG.ERR_PRESSURE_OUT_OF_RANGE,
        VI_Severity := 3,
        VI_Active := fbAnalog_Manifold_Pressure[L_i].VO_Error,
        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
        VI_Source := 100 + L_i,
        VIO_Events := GVL_STATUS.G_Diagnostics_Events,
        VIO_Count := GVL_STATUS.G_Diagnostics_Count
    );

    fbAnalog_Manifold_Current[L_i](
        VI_Raw_Value := L_Manifold_Current_Raw,
        VI_Sensor_Type := 0,
        VI_Min_Scale := 0.0,
        VI_Max_Scale := 16.0,
        VI_Offset := 0.0,
        VI_Multiplier := 1.0,
        VI_Filter_Time_MS := GVL_CONSTANTS.C_MS_IN_SECOND,
        VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
        VI_Fallback_Mode := 0,
        VI_Default_Value := 0.0
    );
    GVL_STATE.G_Manifold_Currents[L_i] := fbAnalog_Manifold_Current[L_i].VO_Value;
    GVL_STATUS.G_Diagnostics.Manifold_Current_Fault[L_i] := fbAnalog_Manifold_Current[L_i].VO_Error;
    GVL_STATUS.G_Diagnostics.Manifold_Current_Diag_Code[L_i] := fbAnalog_Manifold_Current[L_i].VO_Diag_Code;

    fbDiagEventManager(
        VI_Code := GVL_CONFIG.ERR_PUMP_UNDERCURRENT,
        VI_Severity := 3,
        VI_Active := fbAnalog_Manifold_Current[L_i].VO_Error,
        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
        VI_Source := 200 + L_i,
        VIO_Events := GVL_STATUS.G_Diagnostics_Events,
        VIO_Count := GVL_STATUS.G_Diagnostics_Count
    );

    IF GVL_STATUS.G_Diagnostics.Manifold_Pressure_Fault[L_i] OR GVL_STATUS.G_Diagnostics.Manifold_Current_Fault[L_i] THEN
        GVL_STATUS.G_Diagnostics.Sensor_Fault := TRUE;
        GVL_STATUS.G_Diagnostics.Subsystem_Degraded := TRUE;
    END_IF;

    IF GVL_STATUS.G_Diagnostics.Manifold_Pressure_Fault[L_i] AND GVL_STATUS.G_Diagnostics.Manifold_Current_Fault[L_i] THEN
        GVL_STATUS.G_Diagnostics.Manifold_Pressure_Fault_Text := 'Correlated pressure/current fault detected';
        GVL_STATUS.G_Diagnostics.Manifold_Current_Fault_Text := 'Correlated pressure/current fault detected';
    ELSIF GVL_STATUS.G_Diagnostics.Manifold_Pressure_Fault[L_i] AND (GVL_STATUS.G_Diagnostics.Manifold_Pressure_Fault_Text = '') THEN
        GVL_STATUS.G_Diagnostics.Manifold_Pressure_Fault_Text := 'Pressure sensor fault detected';
    ELSIF GVL_STATUS.G_Diagnostics.Manifold_Current_Fault[L_i] AND (GVL_STATUS.G_Diagnostics.Manifold_Current_Fault_Text = '') THEN
        GVL_STATUS.G_Diagnostics.Manifold_Current_Fault_Text := 'Current sensor fault detected';
    END_IF;
END_FOR;

// >>> BULK_SYNC_ANCHOR: PRG_IO_Read_Manifold_01_Pressure_Current <<<
END_PROGRAM
