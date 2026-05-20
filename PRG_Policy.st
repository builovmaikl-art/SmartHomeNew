PROGRAM PRG_Policy
VAR
    L_Away_Elapsed_MS : UDINT;
    L_Restore_Elapsed_MS : UDINT;
    L_Return_Delta_MS : UDINT;
    L_Return_Grace_Elapsed_MS : UDINT;
    L_Away_Return_Window_Reached : BOOL;
    L_Previous_Away_Active : BOOL := FALSE;
    L_Previous_Away_Level : BYTE := 0;
END_VAR

GVL_POLICY.G_Away_Restore_Requested := FALSE;

// ============================================================
// CONFIGURATION SAFETY CLAMP
// ============================================================
// Configuration validation is diagnostic-only here.
// System mode ownership remains in FB_State_Manager via
// FB_System_Health_Orchestrator. Policy must not directly write
// GVL_STATE.G_System_Mode.
IF GVL_CONFIG_VALIDATION.G_Config_Force_Safe_Mode AND
   (NOT GVL_CONFIG_VALIDATION.G_Config_Valid) AND
   (GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_NORMAL) THEN
    GVL_STATUS.G_Diagnostics.Subsystem_Degraded := TRUE;
    GVL_STATUS.G_System_Mode_Text := 'CONFIG DEGRADED';
END_IF;

// ============================================================
// SCENARIO POLICY OWNER
// ============================================================

// 1. Base priority resolution
IF GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_SAFE_STOP THEN
    GVL_POLICY.G_Scenario_Intent := E_SCENARIO_TYPE.SCENARIO_NONE;
    GVL_POLICY.G_Scenario_Source := SRC_SAFETY;

ELSIF GVL_POLICY.G_Scenario_Request_Operator <> E_SCENARIO_TYPE.SCENARIO_NONE THEN
    GVL_POLICY.G_Scenario_Intent := GVL_POLICY.G_Scenario_Request_Operator;
    GVL_POLICY.G_Scenario_Source := SRC_OPERATOR;

ELSIF GVL_POLICY.G_Scenario_Request_Gateway <> E_SCENARIO_TYPE.SCENARIO_NONE THEN
    GVL_POLICY.G_Scenario_Intent := GVL_POLICY.G_Scenario_Request_Gateway;
    GVL_POLICY.G_Scenario_Source := SRC_GATEWAY;

ELSIF GVL_POLICY.G_Scenario_Request_Rule <> E_SCENARIO_TYPE.SCENARIO_NONE THEN
    GVL_POLICY.G_Scenario_Intent := GVL_POLICY.G_Scenario_Request_Rule;
    GVL_POLICY.G_Scenario_Source := SRC_RULE;

ELSE
    GVL_POLICY.G_Scenario_Intent := GVL_STATUS.G_Current_Scenario;
    GVL_POLICY.G_Scenario_Source := SRC_NONE;
END_IF;

// 2. Fail-safe clamp
CASE GVL_STATE.G_System_Mode OF
    E_System_Operating_Mode.MODE_SAFE_STOP:
        GVL_POLICY.G_Scenario_Intent := E_SCENARIO_TYPE.SCENARIO_NONE;
        GVL_POLICY.G_Scenario_Source := SRC_SAFETY;

    E_System_Operating_Mode.MODE_FREEZE_PROTECTION:
        GVL_POLICY.G_Scenario_Intent := E_SCENARIO_TYPE.SCENARIO_NONE;
        GVL_POLICY.G_Scenario_Source := SRC_POLICY;

    E_System_Operating_Mode.MODE_DEGRADED:
        CASE GVL_POLICY.G_Scenario_Intent OF
            E_SCENARIO_TYPE.SCENARIO_NONE,
            E_SCENARIO_TYPE.SCENARIO_PRESENCE,
            E_SCENARIO_TYPE.SCENARIO_AWAY,
            E_SCENARIO_TYPE.SCENARIO_SLEEP:
                ;
        ELSE
            GVL_POLICY.G_Scenario_Intent := E_SCENARIO_TYPE.SCENARIO_NONE;
            GVL_POLICY.G_Scenario_Source := SRC_POLICY;
        END_CASE;
END_CASE;

// 3. Context automation
IF GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_NORMAL THEN
    IF GVL_ALARM.G_Security_Armed AND
       (GVL_POLICY.G_Scenario_Request_Operator = E_SCENARIO_TYPE.SCENARIO_NONE) AND
       (GVL_POLICY.G_Scenario_Request_Gateway = E_SCENARIO_TYPE.SCENARIO_NONE) AND
       (GVL_POLICY.G_Scenario_Request_Rule = E_SCENARIO_TYPE.SCENARIO_NONE) AND
       (GVL_POLICY.G_Scenario_Intent <> E_SCENARIO_TYPE.SCENARIO_AWAY) THEN
        GVL_POLICY.G_Scenario_Intent := E_SCENARIO_TYPE.SCENARIO_AWAY;
        GVL_POLICY.G_Scenario_Source := SRC_POLICY;
    END_IF;
END_IF;

// 4. Degraded adaptation
IF GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_DEGRADED THEN
    IF (GVL_POLICY.G_Scenario_Request_Operator = E_SCENARIO_TYPE.SCENARIO_NONE) AND
       (GVL_POLICY.G_Scenario_Request_Gateway = E_SCENARIO_TYPE.SCENARIO_NONE) AND
       (GVL_POLICY.G_Scenario_Request_Rule = E_SCENARIO_TYPE.SCENARIO_NONE) THEN

        IF GVL_ALARM.G_Security_Armed THEN
            GVL_POLICY.G_Scenario_Intent := E_SCENARIO_TYPE.SCENARIO_AWAY;
            GVL_POLICY.G_Scenario_Source := SRC_POLICY;

        ELSIF GVL_POLICY.G_Scenario_Intent = E_SCENARIO_TYPE.SCENARIO_PRESENCE THEN
            GVL_POLICY.G_Scenario_Intent := E_SCENARIO_TYPE.SCENARIO_SLEEP;
            GVL_POLICY.G_Scenario_Source := SRC_POLICY;
        END_IF;
    END_IF;
END_IF;

// ============================================================
// AWAY LEVEL POLICY
// ============================================================
// 0=none, 1=short, 2=medium, 3=long.
// Short: light 100%, heating -1C, simulation off.
// Medium: light/simulation medium, heating -3C, simulation 0.3.
// Long: minimal reasonable heating economy; planned-return preheat may
// temporarily raise selected rooms before the expected arrival.
L_Away_Return_Window_Reached := FALSE;

IF GVL_POLICY.G_Scenario_Intent = E_SCENARIO_TYPE.SCENARIO_AWAY THEN
    IF NOT GVL_POLICY.G_Away_Active THEN
        GVL_POLICY.G_Away_Active := TRUE;
        GVL_POLICY.G_Away_Start_MS := GVL_TIME_SERVICE.G_Now_MS;
        GVL_POLICY.G_Away_Elapsed_MS := 0;
        GVL_POLICY.G_Away_Level := 1;
        GVL_POLICY.G_Away_Return_Preheat_Active := FALSE;
        GVL_POLICY.G_Away_Return_Grace_Active := FALSE;
        GVL_POLICY.G_Away_Return_Expired := FALSE;
    ELSE
        IF GVL_TIME_SERVICE.G_Now_MS >= GVL_POLICY.G_Away_Start_MS THEN
            L_Away_Elapsed_MS := GVL_TIME_SERVICE.G_Now_MS - GVL_POLICY.G_Away_Start_MS;
        ELSE
            L_Away_Elapsed_MS := (4294967295 - GVL_POLICY.G_Away_Start_MS) + GVL_TIME_SERVICE.G_Now_MS + 1;
        END_IF;

        GVL_POLICY.G_Away_Elapsed_MS := L_Away_Elapsed_MS;

        IF L_Away_Elapsed_MS >= GVL_POLICY.G_Away_Medium_To_Long_MS THEN
            GVL_POLICY.G_Away_Level := 3;
        ELSIF L_Away_Elapsed_MS >= GVL_POLICY.G_Away_Short_To_Medium_MS THEN
            GVL_POLICY.G_Away_Level := 2;
        ELSE
            GVL_POLICY.G_Away_Level := 1;
        END_IF;
    END_IF;

    // Planned return preheat window.
    IF GVL_POLICY.G_Away_Planned_Return_Enabled AND NOT GVL_POLICY.G_Away_Return_Expired THEN
        IF GVL_POLICY.G_Away_Planned_Return_MS >= GVL_TIME_SERVICE.G_Now_MS THEN
            L_Return_Delta_MS := GVL_POLICY.G_Away_Planned_Return_MS - GVL_TIME_SERVICE.G_Now_MS;
            L_Away_Return_Window_Reached := (L_Return_Delta_MS <= GVL_POLICY.G_Away_Preheat_Lead_MS);
        ELSE
            L_Away_Return_Window_Reached := TRUE;
        END_IF;

        IF L_Away_Return_Window_Reached THEN
            GVL_POLICY.G_Away_Return_Preheat_Active := TRUE;

            IF NOT GVL_POLICY.G_Away_Return_Grace_Active THEN
                GVL_POLICY.G_Away_Return_Grace_Active := TRUE;
                GVL_POLICY.G_Away_Return_Grace_Start_MS := GVL_TIME_SERVICE.G_Now_MS;
            END_IF;
        END_IF;

        IF GVL_POLICY.G_Away_Return_Grace_Active THEN
            IF GVL_TIME_SERVICE.G_Now_MS >= GVL_POLICY.G_Away_Return_Grace_Start_MS THEN
                L_Return_Grace_Elapsed_MS := GVL_TIME_SERVICE.G_Now_MS - GVL_POLICY.G_Away_Return_Grace_Start_MS;
            ELSE
                L_Return_Grace_Elapsed_MS := (4294967295 - GVL_POLICY.G_Away_Return_Grace_Start_MS) + GVL_TIME_SERVICE.G_Now_MS + 1;
            END_IF;

            IF L_Return_Grace_Elapsed_MS >= GVL_POLICY.G_Away_Return_Grace_MS THEN
                GVL_POLICY.G_Away_Return_Expired := TRUE;
                GVL_POLICY.G_Away_Return_Preheat_Active := FALSE;
                GVL_POLICY.G_Away_Return_Grace_Active := FALSE;
            END_IF;
        END_IF;
    ELSE
        GVL_POLICY.G_Away_Return_Preheat_Active := FALSE;
        GVL_POLICY.G_Away_Return_Grace_Active := FALSE;
    END_IF;

    CASE GVL_POLICY.G_Away_Level OF
        1:
            GVL_POLICY.G_Away_Simulation_Active := FALSE;
            GVL_POLICY.G_Away_Simulation_Intensity := 0.0;
            GVL_POLICY.G_Away_Heating_Offset_C := -1.0;
        2:
            GVL_POLICY.G_Away_Simulation_Active := TRUE;
            GVL_POLICY.G_Away_Simulation_Intensity := 0.3;
            GVL_POLICY.G_Away_Heating_Offset_C := -3.0;
        3:
            GVL_POLICY.G_Away_Simulation_Active := TRUE;
            GVL_POLICY.G_Away_Simulation_Intensity := 0.2;

            IF GVL_POLICY.G_Away_Return_Preheat_Active THEN
                GVL_POLICY.G_Away_Heating_Offset_C := 0.0;
            ELSE
                GVL_POLICY.G_Away_Heating_Offset_C := GVL_POLICY.G_Away_Long_Economy_Setpoint_C - 22.0;
            END_IF;
    ELSE
            GVL_POLICY.G_Away_Simulation_Active := FALSE;
            GVL_POLICY.G_Away_Simulation_Intensity := 0.0;
            GVL_POLICY.G_Away_Heating_Offset_C := 0.0;
    END_CASE;

ELSE
    IF GVL_POLICY.G_Away_Active AND (GVL_POLICY.G_Away_Level = 1) THEN
        GVL_POLICY.G_Away_Restore_Requested := TRUE;
        GVL_POLICY.G_Away_Restore_Active := TRUE;
        GVL_POLICY.G_Away_Restore_Start_MS := GVL_TIME_SERVICE.G_Now_MS;
    END_IF;

    GVL_POLICY.G_Away_Active := FALSE;
    GVL_POLICY.G_Away_Level := 0;
    GVL_POLICY.G_Away_Elapsed_MS := 0;
    GVL_POLICY.G_Away_Simulation_Active := FALSE;
    GVL_POLICY.G_Away_Simulation_Intensity := 0.0;
    GVL_POLICY.G_Away_Heating_Offset_C := 0.0;
    GVL_POLICY.G_Away_Return_Preheat_Active := FALSE;
    GVL_POLICY.G_Away_Return_Grace_Active := FALSE;
    GVL_POLICY.G_Away_Return_Expired := FALSE;
END_IF;

IF GVL_POLICY.G_Away_Restore_Active THEN
    IF GVL_TIME_SERVICE.G_Now_MS >= GVL_POLICY.G_Away_Restore_Start_MS THEN
        L_Restore_Elapsed_MS := GVL_TIME_SERVICE.G_Now_MS - GVL_POLICY.G_Away_Restore_Start_MS;
    ELSE
        L_Restore_Elapsed_MS := (4294967295 - GVL_POLICY.G_Away_Restore_Start_MS) + GVL_TIME_SERVICE.G_Now_MS + 1;
    END_IF;

    IF L_Restore_Elapsed_MS >= GVL_POLICY.G_Away_Restore_Duration_MS THEN
        GVL_POLICY.G_Away_Restore_Progress := 1.0;
        GVL_POLICY.G_Away_Restore_Active := FALSE;
    ELSE
        GVL_POLICY.G_Away_Restore_Progress := TO_REAL(L_Restore_Elapsed_MS) / TO_REAL(GVL_POLICY.G_Away_Restore_Duration_MS);
    END_IF;
ELSE
    GVL_POLICY.G_Away_Restore_Progress := 0.0;
END_IF;

L_Previous_Away_Active := GVL_POLICY.G_Away_Active;
L_Previous_Away_Level := GVL_POLICY.G_Away_Level;

// 5. Heating bridge
// Policy publishes preheat intent only. Actual per-circuit comfort/economy
// target selection is owned by FB_Heating_Circuit_Control through
// ST_FloorHeating_Circuit_Config.
GVL_STATE.G_Preheat_Request :=
    GVL_POLICY.G_Rule_Preheat_Request OR GVL_POLICY.G_Away_Return_Preheat_Active;
GVL_HEATING_REQUEST.G_Preheat_Request := GVL_STATE.G_Preheat_Request;
GVL_HEATING_REQUEST.G_Target_Temperature := GVL_STATE.G_Target_Temperature;

GVL_STATE.G_Freeze_Request :=
    (GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_FREEZE_PROTECTION);
GVL_HEATING_REQUEST.G_Freeze_Request := GVL_STATE.G_Freeze_Request;
END_PROGRAM