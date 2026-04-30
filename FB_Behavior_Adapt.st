FUNCTION_BLOCK FB_Behavior_Adapt
VAR_INPUT
    iScenario : E_System_Reason_Code;
    iSuccess : BOOL;
END_VAR

VAR
    L_Weight : REAL;
END_VAR

IF NOT GVL_BEHAVIOR_ADAPT.G_Adapt_Enabled THEN RETURN; END_IF;

GVL_BEHAVIOR_ADAPT.G_Scenario_Stats[iScenario].Activations :=
    GVL_BEHAVIOR_ADAPT.G_Scenario_Stats[iScenario].Activations + 1;

IF iSuccess THEN
    GVL_BEHAVIOR_ADAPT.G_Scenario_Stats[iScenario].Success_Count :=
        GVL_BEHAVIOR_ADAPT.G_Scenario_Stats[iScenario].Success_Count + 1;
ELSE
    GVL_BEHAVIOR_ADAPT.G_Scenario_Stats[iScenario].Failure_Count :=
        GVL_BEHAVIOR_ADAPT.G_Scenario_Stats[iScenario].Failure_Count + 1;
END_IF;

CASE iScenario OF
    REASON_SCENARIO_VENT_BOOST:
        L_Weight := GVL_BEHAVIOR_ADAPT.G_Behavior_Weights.W_VentBoost;

        IF iSuccess THEN
            L_Weight := L_Weight + GVL_BEHAVIOR_ADAPT.G_Adapt_Learning_Rate;
        ELSE
            L_Weight := L_Weight - GVL_BEHAVIOR_ADAPT.G_Adapt_Learning_Rate;
        END_IF;

        IF L_Weight > 2.0 THEN L_Weight := 2.0; END_IF;
        IF L_Weight < 0.5 THEN L_Weight := 0.5; END_IF;

        GVL_BEHAVIOR_ADAPT.G_Behavior_Weights.W_VentBoost := L_Weight;
END_CASE;