FUNCTION_BLOCK FB_Behavior_Adapt
VAR_INPUT
    iScenario : E_System_Reason_Code;
    iSuccess : BOOL;
    iMeasuredValue : REAL;
    iZone : INT;
    iConfidence : REAL;
END_VAR

VAR
    L_Stats : ST_Scenario_Stats;
    L_Zone : ST_Zone_Adapt_State;
    L_Weight : REAL;
    L_Adjustment : REAL;
END_VAR

IF NOT GVL_BEHAVIOR_ADAPT.G_Adapt_Enabled THEN RETURN; END_IF;

// =====================
// GLOBAL SCENARIO STATS
// =====================
L_Stats := GVL_BEHAVIOR_ADAPT.G_Scenario_Stats[iScenario];
L_Stats.Activations := L_Stats.Activations + 1;

IF iSuccess THEN
    L_Stats.Success_Count := L_Stats.Success_Count + 1;
ELSE
    L_Stats.Failure_Count := L_Stats.Failure_Count + 1;
END_IF;

L_Stats.Avg_Result_Value :=
    (L_Stats.Avg_Result_Value * (L_Stats.Activations - 1) + iMeasuredValue)
    / L_Stats.Activations;

IF L_Stats.Activations > 0 THEN
    L_Stats.Success_Rate :=
        REAL(L_Stats.Success_Count) / REAL(L_Stats.Activations);
END_IF;

// =====================
// ZONE-LEVEL ADAPTATION (VENT BOOST ONLY)
// =====================
IF (iScenario = REASON_SCENARIO_VENT_BOOST) AND (iZone >= 1) AND (iZone <= GVL_CONSTANTS.C_MAX_ZONES) THEN

    L_Zone := GVL_BEHAVIOR_ADAPT.G_VentBoost_Zone_Adapt[iZone];

    IF L_Zone.Zone_Weight = 0.0 THEN
        L_Zone.Zone_Weight := GVL_BEHAVIOR_ADAPT.G_Adapt_Default_Zone_Weight;
    END_IF;

    L_Zone.Activations := L_Zone.Activations + 1;

    IF iSuccess THEN
        L_Zone.Success_Count := L_Zone.Success_Count + 1;
    ELSE
        L_Zone.Failure_Count := L_Zone.Failure_Count + 1;
    END_IF;

    L_Zone.Avg_Result_Value :=
        (L_Zone.Avg_Result_Value * (L_Zone.Activations - 1) + iMeasuredValue)
        / L_Zone.Activations;

    IF L_Zone.Activations > 0 THEN
        L_Zone.Success_Rate :=
            REAL(L_Zone.Success_Count) / REAL(L_Zone.Activations);
    END_IF;

    // confidence-weighted adjustment
    IF (L_Zone.Activations MOD GVL_BEHAVIOR_ADAPT.G_Adapt_Update_Threshold) = 0 THEN

        IF iConfidence >= GVL_BEHAVIOR_ADAPT.G_Adapt_Min_Confidence THEN

            L_Adjustment :=
                (L_Zone.Success_Rate - 0.5)
                * GVL_BEHAVIOR_ADAPT.G_Adapt_Learning_Rate
                * iConfidence;

            L_Zone.Zone_Weight := L_Zone.Zone_Weight + L_Adjustment;

            IF L_Zone.Zone_Weight > 2.0 THEN L_Zone.Zone_Weight := 2.0; END_IF;
            IF L_Zone.Zone_Weight < 0.5 THEN L_Zone.Zone_Weight := 0.5; END_IF;

        END_IF;

    END_IF;

    GVL_BEHAVIOR_ADAPT.G_VentBoost_Zone_Adapt[iZone] := L_Zone;

END_IF;

// =====================
// GLOBAL WEIGHT UPDATE
// =====================
IF (L_Stats.Activations MOD GVL_BEHAVIOR_ADAPT.G_Adapt_Update_Threshold) = 0 THEN

    L_Adjustment :=
        (L_Stats.Success_Rate - 0.5)
        * GVL_BEHAVIOR_ADAPT.G_Adapt_Learning_Rate;

    CASE iScenario OF
        REASON_SCENARIO_NIGHT:
            GVL_BEHAVIOR_ADAPT.G_Behavior_Weights.W_Night := LIMIT(0.5, GVL_BEHAVIOR_ADAPT.G_Behavior_Weights.W_Night + L_Adjustment, 2.0);
        REASON_SCENARIO_PREHEAT:
            GVL_BEHAVIOR_ADAPT.G_Behavior_Weights.W_Preheat := LIMIT(0.5, GVL_BEHAVIOR_ADAPT.G_Behavior_Weights.W_Preheat + L_Adjustment, 2.0);
        REASON_SCENARIO_VENT_BOOST:
            GVL_BEHAVIOR_ADAPT.G_Behavior_Weights.W_VentBoost := LIMIT(0.5, GVL_BEHAVIOR_ADAPT.G_Behavior_Weights.W_VentBoost + L_Adjustment, 2.0);
        REASON_SCENARIO_ACCESS_SECURE:
            GVL_BEHAVIOR_ADAPT.G_Behavior_Weights.W_AccessSecure := LIMIT(0.5, GVL_BEHAVIOR_ADAPT.G_Behavior_Weights.W_AccessSecure + L_Adjustment, 2.0);
        REASON_SCENARIO_COMFORT:
            GVL_BEHAVIOR_ADAPT.G_Behavior_Weights.W_Comfort := LIMIT(0.5, GVL_BEHAVIOR_ADAPT.G_Behavior_Weights.W_Comfort + L_Adjustment, 2.0);
    END_CASE;

END_IF;

GVL_BEHAVIOR_ADAPT.G_Scenario_Stats[iScenario] := L_Stats;