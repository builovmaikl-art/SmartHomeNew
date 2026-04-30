FUNCTION_BLOCK FB_Behavior_Adapt
VAR_INPUT
    iScenario : E_System_Reason_Code;
    iSuccess : BOOL;
    iMeasuredValue : REAL;
END_VAR

VAR
    L_Stats : ST_Scenario_Stats;
    L_Weight : REAL;
    L_Adjustment : REAL;
END_VAR

IF NOT GVL_BEHAVIOR_ADAPT.G_Adapt_Enabled THEN RETURN; END_IF;

L_Stats := GVL_BEHAVIOR_ADAPT.G_Scenario_Stats[iScenario];

L_Stats.Activations := L_Stats.Activations + 1;

IF iSuccess THEN
    L_Stats.Success_Count := L_Stats.Success_Count + 1;
ELSE
    L_Stats.Failure_Count := L_Stats.Failure_Count + 1;
END_IF;

// average value
L_Stats.Avg_Result_Value :=
    (L_Stats.Avg_Result_Value * (L_Stats.Activations - 1) + iMeasuredValue)
    / L_Stats.Activations;

// success rate
IF L_Stats.Activations > 0 THEN
    L_Stats.Success_Rate :=
        REAL(L_Stats.Success_Count) / REAL(L_Stats.Activations);
END_IF;

// stabilization
IF (L_Stats.Activations MOD GVL_BEHAVIOR_ADAPT.G_Adapt_Update_Threshold) = 0 THEN

    CASE iScenario OF
        REASON_SCENARIO_NIGHT:
            L_Weight := GVL_BEHAVIOR_ADAPT.G_Behavior_Weights.W_Night;
        REASON_SCENARIO_PREHEAT:
            L_Weight := GVL_BEHAVIOR_ADAPT.G_Behavior_Weights.W_Preheat;
        REASON_SCENARIO_VENT_BOOST:
            L_Weight := GVL_BEHAVIOR_ADAPT.G_Behavior_Weights.W_VentBoost;
        REASON_SCENARIO_ACCESS_SECURE:
            L_Weight := GVL_BEHAVIOR_ADAPT.G_Behavior_Weights.W_AccessSecure;
        REASON_SCENARIO_COMFORT:
            L_Weight := GVL_BEHAVIOR_ADAPT.G_Behavior_Weights.W_Comfort;
    END_CASE;

    L_Adjustment :=
        (L_Stats.Success_Rate - 0.5) * GVL_BEHAVIOR_ADAPT.G_Adapt_Learning_Rate;

    L_Weight := L_Weight + L_Adjustment;

    IF L_Weight > 2.0 THEN L_Weight := 2.0; END_IF;
    IF L_Weight < 0.5 THEN L_Weight := 0.5; END_IF;

    CASE iScenario OF
        REASON_SCENARIO_NIGHT:
            GVL_BEHAVIOR_ADAPT.G_Behavior_Weights.W_Night := L_Weight;
        REASON_SCENARIO_PREHEAT:
            GVL_BEHAVIOR_ADAPT.G_Behavior_Weights.W_Preheat := L_Weight;
        REASON_SCENARIO_VENT_BOOST:
            GVL_BEHAVIOR_ADAPT.G_Behavior_Weights.W_VentBoost := L_Weight;
        REASON_SCENARIO_ACCESS_SECURE:
            GVL_BEHAVIOR_ADAPT.G_Behavior_Weights.W_AccessSecure := L_Weight;
        REASON_SCENARIO_COMFORT:
            GVL_BEHAVIOR_ADAPT.G_Behavior_Weights.W_Comfort := L_Weight;
    END_CASE;

END_IF;

GVL_BEHAVIOR_ADAPT.G_Scenario_Stats[iScenario] := L_Stats;