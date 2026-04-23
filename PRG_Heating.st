PROGRAM PRG_Heating

VAR
    L_Last_Mode : INT := 0; // 0=normal,1=preheat,2=freeze
    L_Mode_Hold_Timer : FB_System_Timer;
END_VAR

VAR
    fbHeatingManager : FB_Heating_System_Manager;
    fbDHWManager : FB_DHW_Manager;
    L_i : INT;
    L_Zone_Valves_8 : ARRAY[1..8] OF BOOL;
    L_Boiler_Modulation_REAL : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF REAL;
    L_Heating_Emergency_Stop : BOOL;
    L_Heating_Gas_Safety_Stop : BOOL;
    L_Heating_DHW_Demand : BOOL;

    fbRecovery : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF FB_System_Timer;
    fbFaultDebounce : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF FB_System_Timer;
    L_FaultCounter : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF INT;
    L_FaultActiveStable : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    L_FaultActiveStablePrev : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    L_Sensor_OOS_Latch : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    L_SoftDegrade : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;

    // Energy management
    L_ActiveCount : INT;
    L_DisableMask : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    L_ToDisable : INT;
    L_ThermalLoad : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL;
    L_TotalLoad : REAL;
    L_CircuitIdx : INT;
    L_ManifoldId : INT;

    // Time slicing (Wave 4.3)
    L_TimeSlot : INT;
    L_TimeWindow : UDINT := 10000;
    L_EnableBySlot : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
END_VAR

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BOILERS DO
    L_Boiler_Modulation_REAL[L_i] := TO_REAL(GVL_IO.AI_Boiler_Modulation[L_i]);
END_FOR;

L_Heating_Emergency_Stop := GVL_STATE.G_Safety_Emergency_Stop;
L_Heating_Gas_Safety_Stop := GVL_STATE.G_Safety_Gas_Latched;
L_Heating_DHW_Demand := fbDHWManager.VO_Heating_Pump;

IF L_Heating_Emergency_Stop THEN
    L_Heating_Gas_Safety_Stop := FALSE;
    L_Heating_DHW_Demand := FALSE;
ELSIF L_Heating_Gas_Safety_Stop THEN
    L_Heating_DHW_Demand := FALSE;
ELSIF GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_DEGRADED THEN
    L_Heating_DHW_Demand := FALSE;
END_IF;

L_Mode_Hold_Timer(IN := TRUE, PT := T#30s, VI_System_Time_MS := GVL_STATUS.G_System_Time_MS);

IF L_Mode_Hold_Timer.Q THEN
    IF GVL_STATE.G_Freeze_Request THEN
        L_Last_Mode := 2;
    ELSIF GVL_STATE.G_Preheat_Request THEN
        L_Last_Mode := 1;
    ELSE
        L_Last_Mode := 0;
    END_IF;
END_IF;

CASE L_Last_Mode OF
    2: GVL_STATE.G_Target_Temperature := 5.0;
    1: GVL_STATE.G_Target_Temperature := 22.0;
    ELSE GVL_STATE.G_Target_Temperature := 20.0;
END_CASE;

fbHeatingManager(
    VI_Preheat_Request := GVL_HEATING_REQUEST.G_Preheat_Request,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Current_TOD := GVL_STATUS.G_Current_TOD,
    VI_IsActivePLC := GVL_STATUS.G_Is_Active_PLC,
    VI_Outdoor_Temp := GVL_STATE.G_Outdoor_Temp,
    VI_Floor_Temps := GVL_STATE.G_Floor_Temps,
    VI_Room_Temps := GVL_STATE.G_Room_Temps,
    VI_Config := GVL_CONFIG.G_Heating_Config,
    VI_Zone_Configs := GVL_CONFIG.G_HMI_FloorHeating_Configs,
    VI_Tariff := GVL_CONFIG.G_HMI_Tariff_Settings,
    VI_Current_Hour := TO_UINT(GVL_STATUS.G_Time_Of_Day_MS / GVL_CONSTANTS.C_MS_IN_HOUR),
    VI_Manifold_Pressures := GVL_STATE.G_Manifold_Pressures,
    VI_Manifold_Currents := GVL_STATE.G_Manifold_Currents,
    VI_Manifold_Temps_Supply := GVL_STATE.G_Manifold_T_Supply,
    VI_Manifold_Temps_Return := GVL_STATE.G_Manifold_T_Return,
    VI_Boiler_Modulation := L_Boiler_Modulation_REAL,
    VI_IO_Modules_Online := GVL_STATUS.G_IO_Modules_Online,
    VI_DHW_Heating_Demand := L_Heating_DHW_Demand,
    VI_System_Mode := GVL_STATE.G_System_Mode,
    VO_Manifold_Valves => GVL_STATE.G_Manifold_Valves,
    VO_Manifold_Pumps => GVL_STATE.G_Manifold_Pumps,
    VO_Zone_Valves => L_Zone_Valves_8
);

// ===== ENERGY LAYER (Wave 4.1) =====
L_ActiveCount := 0;
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    L_DisableMask[L_i] := FALSE;
    IF GVL_STATE.G_Manifold_Pumps[L_i] THEN
        L_ActiveCount := L_ActiveCount + 1;
    END_IF;
END_FOR;

L_ToDisable := 0;
IF (NOT GVL_STATE.G_Safety_Freeze_Risk) AND (L_ActiveCount > GVL_CONFIG.G_Max_Active_Manifolds) THEN
    L_ToDisable := L_ActiveCount - GVL_CONFIG.G_Max_Active_Manifolds;

    // first pass: disable only as many priority 1 as needed
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
        IF (L_ToDisable > 0) AND (GVL_CONFIG.G_Manifold_Priority[L_i] = 1) AND GVL_STATE.G_Manifold_Pumps[L_i] THEN
            L_DisableMask[L_i] := TRUE;
            L_ToDisable := L_ToDisable - 1;
        END_IF;
    END_FOR;

    // second pass: disable only as many priority 2 as still needed
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
        IF (L_ToDisable > 0) AND (GVL_CONFIG.G_Manifold_Priority[L_i] = 2) AND GVL_STATE.G_Manifold_Pumps[L_i] THEN
            L_DisableMask[L_i] := TRUE;
            L_ToDisable := L_ToDisable - 1;
        END_IF;
    END_FOR;
END_IF;
// ==================================

// ===== THERMAL BUDGET (Wave 4.2) =====
L_TotalLoad := 0.0;
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    L_ThermalLoad[L_i] := 0.0;
END_FOR;

FOR L_CircuitIdx := 1 TO 8 DO
    L_ManifoldId := GVL_CONFIG.G_HMI_FloorHeating_Configs[L_CircuitIdx].manifold_id;
    IF (L_ManifoldId >= 1) AND (L_ManifoldId <= GVL_CONSTANTS.C_MAX_MANIFOLDS) THEN
        IF GVL_STATE.G_Manifold_Pumps[L_ManifoldId] THEN
            L_ThermalLoad[L_ManifoldId] := L_ThermalLoad[L_ManifoldId] +
                (GVL_CONFIG.G_HMI_FloorHeating_Configs[L_CircuitIdx].design_temp / 35.0);
        END_IF;
    END_IF;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    L_TotalLoad := L_TotalLoad + L_ThermalLoad[L_i];
END_FOR;

IF (NOT GVL_STATE.G_Safety_Freeze_Risk) AND (L_TotalLoad > GVL_CONFIG.G_Max_Thermal_Budget) THEN
    // first pass: priority 1 manifolds not already disabled
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
        IF (L_TotalLoad > GVL_CONFIG.G_Max_Thermal_Budget)
           AND (GVL_CONFIG.G_Manifold_Priority[L_i] = 1)
           AND GVL_STATE.G_Manifold_Pumps[L_i]
           AND NOT L_DisableMask[L_i] THEN
            L_DisableMask[L_i] := TRUE;
            L_TotalLoad := L_TotalLoad - L_ThermalLoad[L_i];
        END_IF;
    END_FOR;

    // second pass: priority 2 manifolds if still above budget
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
        IF (L_TotalLoad > GVL_CONFIG.G_Max_Thermal_Budget)
           AND (GVL_CONFIG.G_Manifold_Priority[L_i] = 2)
           AND GVL_STATE.G_Manifold_Pumps[L_i]
           AND NOT L_DisableMask[L_i] THEN
            L_DisableMask[L_i] := TRUE;
            L_TotalLoad := L_TotalLoad - L_ThermalLoad[L_i];
        END_IF;
    END_FOR;
END_IF;
// ====================================

// ===== TIME SLICING (Wave 4.3) =====
L_TimeSlot := (GVL_STATUS.G_System_Time_MS / L_TimeWindow) MOD GVL_CONSTANTS.C_MAX_MANIFOLDS;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    L_EnableBySlot[L_i] := FALSE;

    IF L_DisableMask[L_i] THEN
        IF ((L_i - 1) MOD GVL_CONSTANTS.C_MAX_MANIFOLDS) = L_TimeSlot THEN
            L_EnableBySlot[L_i] := TRUE;
        END_IF;
    ELSE
        L_EnableBySlot[L_i] := TRUE;
    END_IF;
END_FOR;
// ====================================

GVL_STATUS.G_Diagnostics.Manifold_Sensor_Out_Of_Service_Active := FALSE;
GVL_STATUS.G_Diagnostics.Manifold_Sensor_First_OOS_Index := 0;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO

    fbFaultDebounce[L_i](
        IN := (
            GVL_STATUS.G_Diagnostics.Manifold_Pressure_Fault[L_i] OR
            GVL_STATUS.G_Diagnostics.Manifold_Current_Fault[L_i] OR
            GVL_STATUS.G_Diagnostics.Manifold_Return_Temp_Fault[L_i]
        ),
        PT := T#3s,
        VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
    );
    L_FaultActiveStable[L_i] := fbFaultDebounce[L_i].Q;

    IF L_FaultActiveStable[L_i] AND NOT L_FaultActiveStablePrev[L_i] THEN
        IF L_FaultCounter[L_i] < 32767 THEN
            L_FaultCounter[L_i] := L_FaultCounter[L_i] + 1;
        END_IF;
    END_IF;
    L_FaultActiveStablePrev[L_i] := L_FaultActiveStable[L_i];

    IF L_FaultCounter[L_i] >= 5 THEN
        L_Sensor_OOS_Latch[L_i] := TRUE;
    END_IF;

    IF GVL_INTENT_USER.I_Reset_Errors THEN
        L_Sensor_OOS_Latch[L_i] := FALSE;
        L_FaultCounter[L_i] := 0;
    END_IF;

    L_SoftDegrade[L_i] := L_FaultActiveStable[L_i] AND NOT L_Sensor_OOS_Latch[L_i];

    fbRecovery[L_i](
        IN := NOT L_FaultActiveStable[L_i] AND NOT L_Sensor_OOS_Latch[L_i],
        PT := T#10s,
        VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
    );

    IF L_Sensor_OOS_Latch[L_i] THEN
        GVL_STATE.G_Manifold_Pumps[L_i] := FALSE;
        GVL_STATE.G_Manifold_Valves[L_i] := FALSE;

    ELSIF L_DisableMask[L_i] AND NOT L_EnableBySlot[L_i] THEN
        GVL_STATE.G_Manifold_Pumps[L_i] := FALSE;
        GVL_STATE.G_Manifold_Valves[L_i] := FALSE;

    ELSIF GVL_STATE.G_Safety_Freeze_Risk THEN
        GVL_STATE.G_Manifold_Pumps[L_i] := TRUE;
        GVL_STATE.G_Manifold_Valves[L_i] := TRUE;

    ELSIF GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_FREEZE_PROTECTION THEN
        CASE GVL_CONFIG.G_Manifold_Priority[L_i] OF
            3:
                GVL_STATE.G_Manifold_Pumps[L_i] := TRUE;
                GVL_STATE.G_Manifold_Valves[L_i] := TRUE;
            2:
                GVL_STATE.G_Manifold_Pumps[L_i] := TRUE;
            ELSE
                GVL_STATE.G_Manifold_Pumps[L_i] := FALSE;
                GVL_STATE.G_Manifold_Valves[L_i] := FALSE;
        END_CASE;

    ELSIF L_SoftDegrade[L_i] THEN
        CASE GVL_CONFIG.G_Manifold_Priority[L_i] OF
            3:
                GVL_STATE.G_Manifold_Pumps[L_i] := TRUE;
                GVL_STATE.G_Manifold_Valves[L_i] := TRUE;
            2:
                GVL_STATE.G_Manifold_Pumps[L_i] := TRUE;
            ELSE
                GVL_STATE.G_Manifold_Pumps[L_i] := FALSE;
                GVL_STATE.G_Manifold_Valves[L_i] := FALSE;
        END_CASE;

    ELSIF NOT fbRecovery[L_i].Q THEN
        GVL_STATE.G_Manifold_Pumps[L_i] := FALSE;
        GVL_STATE.G_Manifold_Valves[L_i] := FALSE;
    END_IF;

    GVL_STATUS.G_Diagnostics.Manifold_Sensor_Fault_Count[L_i] := L_FaultCounter[L_i];
    GVL_STATUS.G_Diagnostics.Manifold_Sensor_Out_Of_Service[L_i] := L_Sensor_OOS_Latch[L_i];

    IF L_Sensor_OOS_Latch[L_i] AND NOT GVL_STATUS.G_Diagnostics.Manifold_Sensor_Out_Of_Service_Active THEN
        GVL_STATUS.G_Diagnostics.Manifold_Sensor_Out_Of_Service_Active := TRUE;
        GVL_STATUS.G_Diagnostics.Manifold_Sensor_First_OOS_Index := L_i;
    END_IF;

END_FOR;

// >>> BULK_SYNC_ANCHOR: PRG_Heating <<<

FOR L_i := 1 TO 8 DO
    GVL_STATE.G_Zone_Valves[L_i] := L_Zone_Valves_8[L_i];
END_FOR;
