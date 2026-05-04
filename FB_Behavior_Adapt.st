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
    L_Adjustment : REAL;
    L_Decay : REAL;
    idx : INT;
END_VAR

IF NOT GVL_BEHAVIOR_ADAPT.G_Adapt_Enabled THEN RETURN; END_IF;

idx := USINT_TO_INT(iScenario);

L_Stats := GVL_BEHAVIOR_ADAPT.G_Scenario_Stats[idx];
L_Stats.Activations := L_Stats.Activations + 1;

IF iSuccess THEN
    L_Stats.Success_Count := L_Stats.Success_Count + 1;
ELSE
    L_Stats.Failure_Count := L_Stats.Failure_Count + 1;
END_IF;

IF L_Stats.Activations > 0 THEN
    L_Stats.Success_Rate := INT_TO_REAL(L_Stats.Success_Count) / INT_TO_REAL(L_Stats.Activations);
END_IF;

IF (iScenario = REASON_SCENARIO_VENT_BOOST) AND (iZone >= 1) AND (iZone <= GVL_CONSTANTS.C_MAX_ZONES) THEN

    L_Zone := GVL_BEHAVIOR_ADAPT.G_VentBoost_Zone_Adapt[iZone];

    IF L_Zone.Zone_Weight = 0.0 THEN
        L_Zone.Zone_Weight := GVL_BEHAVIOR_ADAPT.G_Adapt_Default_Zone_Weight;
    END_IF;

    L_Decay := GVL_BEHAVIOR_ADAPT.G_Decay_Factor;
    L_Zone.Zone_Weight := L_Zone.Zone_Weight * L_Decay;
    L_Zone.Confidence := L_Zone.Confidence * L_Decay;

    L_Zone.Activations := L_Zone.Activations + 1;

    IF iSuccess THEN
        L_Zone.Success_Count := L_Zone.Success_Count + 1;
    ELSE
        L_Zone.Failure_Count := L_Zone.Failure_Count + 1;
    END_IF;

    IF L_Zone.Activations > 0 THEN
        L_Zone.Success_Rate := INT_TO_REAL(L_Zone.Success_Count) / INT_TO_REAL(L_Zone.Activations);
    END_IF;

    IF iConfidence >= GVL_BEHAVIOR_ADAPT.G_Adapt_Min_Confidence THEN
        L_Zone.Confidence := L_Zone.Confidence +
            (iConfidence - L_Zone.Confidence) * GVL_BEHAVIOR_ADAPT.G_Confidence_Learning_Rate;
    END_IF;

    IF (L_Zone.Activations MOD GVL_BEHAVIOR_ADAPT.G_Adapt_Update_Threshold) = 0 THEN

        L_Adjustment :=
            (L_Zone.Success_Rate - 0.5)
            * GVL_BEHAVIOR_ADAPT.G_Adapt_Learning_Rate
            * L_Zone.Confidence;

        L_Zone.Zone_Weight := LIMIT(0.5, L_Zone.Zone_Weight + L_Adjustment, 2.0);

    END_IF;

    L_Zone.Last_Update_MS := GVL_TIME_SERVICE.G_Now_MS;

    GVL_BEHAVIOR_ADAPT.G_VentBoost_Zone_Adapt[iZone] := L_Zone;

END_IF;

GVL_BEHAVIOR_ADAPT.G_Scenario_Stats[idx] := L_Stats;
END_FUNCTION_BLOCK
