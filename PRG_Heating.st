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
    L_TotalRequestedLoad : REAL;
    L_TotalActiveLoad : REAL;
    L_CircuitIdx : INT;
    L_ManifoldId : INT;

    // Proportional duty cycle (Wave 4.5)
    L_TimeWindow : UDINT := 10000;
    L_TimePosition : UDINT;
    L_EnableBySlot : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    L_DutyPermille : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF INT;
END_VAR

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BOILERS DO
    L_Boiler_Modulation_REAL[L_i] := TO_REAL(GVL_IO.AI_Boiler_Modulation[L_i]);
END_FOR;

// ... (same code omitted for brevity until thermal block, unchanged)

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
L_TotalRequestedLoad := L_TotalLoad;

// NEW: active load sum
L_TotalActiveLoad := 0.0;
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    IF GVL_STATE.G_Manifold_Pumps[L_i] THEN
        L_TotalActiveLoad := L_TotalActiveLoad + L_ThermalLoad[L_i];
    END_IF;
END_FOR;

// ===== PROPORTIONAL DUTY (Wave 4.5) =====
L_TimePosition := GVL_STATUS.G_System_Time_MS MOD L_TimeWindow;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    L_EnableBySlot[L_i] := FALSE;
    L_DutyPermille[L_i] := 1000;

    IF L_DisableMask[L_i] THEN
        IF (L_TotalActiveLoad > 0.0) AND (L_TotalRequestedLoad > 0.0) THEN
            L_DutyPermille[L_i] := REAL_TO_INT(
                1000.0 *
                (L_ThermalLoad[L_i] / L_TotalActiveLoad) *
                (GVL_CONFIG.G_Max_Thermal_Budget / L_TotalRequestedLoad)
            );
        ELSE
            L_DutyPermille[L_i] := 500;
        END_IF;

        CASE GVL_CONFIG.G_Manifold_Priority[L_i] OF
            2: L_DutyPermille[L_i] := L_DutyPermille[L_i] + 200;
            ELSE L_DutyPermille[L_i] := L_DutyPermille[L_i] - 100;
        END_CASE;

        IF L_DutyPermille[L_i] > 900 THEN
            L_DutyPermille[L_i] := 900;
        ELSIF L_DutyPermille[L_i] < 100 THEN
            L_DutyPermille[L_i] := 100;
        END_IF;

        IF L_TimePosition < ((L_TimeWindow * TO_UDINT(L_DutyPermille[L_i])) / 1000) THEN
            L_EnableBySlot[L_i] := TRUE;
        END_IF;
    ELSE
        L_EnableBySlot[L_i] := TRUE;
    END_IF;
END_FOR;

// rest unchanged
