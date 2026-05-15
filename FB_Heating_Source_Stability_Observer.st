// ==============================================================================
// Heating source stability observer
//
// Predictive observability-only layer.
//
// DOES NOT own runtime authority.
// DOES NOT own outputs.
// DOES NOT close valves.
// DOES NOT modify heating demand.
// DOES NOT override runtime decisions.
//
// Observes:
// - source switching frequency
// - fallback oscillation
// - degradation persistence
// - recovery trends
// - confidence volatility
//
// Publishes predictive instability semantics only.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Source_Stability_Observer
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
END_VAR

VAR
    L_i : INT;

    L_Last_Confidence : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF REAL;

    L_Confidence_Delta : REAL;
    L_Confidence_Volatility : REAL;
    L_Source_Trust_Trend : REAL;
    L_Instability_Score : REAL;
END_VAR

IF NOT VI_Enable THEN
    RETURN;
END_IF;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO

    // ======================================================
    // VISIBILITY
    // ======================================================
    GVL_Heating_Source_Stability.G_State[L_i].Visible := TRUE;

    // ======================================================
    // EDGE COUNTING
    // ======================================================
    IF GVL_Heating_Circuit_Explainability.G_Source_Switched_Event[L_i] THEN
        IF GVL_Heating_Source_Stability.G_State[L_i].Source_Switch_Count < 65535 THEN
            GVL_Heating_Source_Stability.G_State[L_i].Source_Switch_Count :=
                GVL_Heating_Source_Stability.G_State[L_i].Source_Switch_Count + 1;
        END_IF;

        GVL_Heating_Source_Stability.G_State[L_i].Last_Observation_MS :=
            VI_System_Time_MS;
    END_IF;

    IF GVL_Heating_Circuit_Explainability.G_Fallback_Activated_Event[L_i] THEN
        IF GVL_Heating_Source_Stability.G_State[L_i].Fallback_Activation_Count < 65535 THEN
            GVL_Heating_Source_Stability.G_State[L_i].Fallback_Activation_Count :=
                GVL_Heating_Source_Stability.G_State[L_i].Fallback_Activation_Count + 1;
        END_IF;

        GVL_Heating_Source_Stability.G_State[L_i].Last_Observation_MS :=
            VI_System_Time_MS;
    END_IF;

    IF GVL_Heating_Circuit_Explainability.G_Fallback_Recovered_Event[L_i] THEN
        IF GVL_Heating_Source_Stability.G_State[L_i].Fallback_Recovery_Count < 65535 THEN
            GVL_Heating_Source_Stability.G_State[L_i].Fallback_Recovery_Count :=
                GVL_Heating_Source_Stability.G_State[L_i].Fallback_Recovery_Count + 1;
        END_IF;

        GVL_Heating_Source_Stability.G_State[L_i].Last_Observation_MS :=
            VI_System_Time_MS;
    END_IF;

    IF GVL_Heating_Circuit_Explainability.G_Source_Loss_Event[L_i] THEN
        IF GVL_Heating_Source_Stability.G_State[L_i].Source_Loss_Count < 65535 THEN
            GVL_Heating_Source_Stability.G_State[L_i].Source_Loss_Count :=
                GVL_Heating_Source_Stability.G_State[L_i].Source_Loss_Count + 1;
        END_IF;

        GVL_Heating_Source_Stability.G_State[L_i].Last_Observation_MS :=
            VI_System_Time_MS;
    END_IF;

    // ======================================================
    // CONFIDENCE VOLATILITY
    // ======================================================
    L_Confidence_Delta := ABS(
        GVL_Heating_Circuit_Explainability.G_Selected_Source_Confidence[L_i] -
        L_Last_Confidence[L_i]
    );

    L_Confidence_Volatility :=
        GVL_Heating_Source_Stability.G_State[L_i].Confidence_Volatility * REAL#0.90 +
        L_Confidence_Delta * REAL#0.10;

    IF L_Confidence_Volatility < REAL#0.0 THEN
        L_Confidence_Volatility := REAL#0.0;
    ELSIF L_Confidence_Volatility > REAL#1.0 THEN
        L_Confidence_Volatility := REAL#1.0;
    END_IF;

    GVL_Heating_Source_Stability.G_State[L_i].Confidence_Volatility :=
        L_Confidence_Volatility;

    // ======================================================
    // SOURCE TRUST TREND
    // ======================================================
    L_Source_Trust_Trend :=
        GVL_Heating_Source_Stability.G_State[L_i].Source_Trust_Trend * REAL#0.95 +
        GVL_Heating_Circuit_Explainability.G_Selected_Source_Confidence[L_i] * REAL#0.05;

    IF GVL_Heating_Circuit_Explainability.G_Source_Degraded[L_i] THEN
        L_Source_Trust_Trend := L_Source_Trust_Trend * REAL#0.98;
    END_IF;

    IF L_Source_Trust_Trend < REAL#0.0 THEN
        L_Source_Trust_Trend := REAL#0.0;
    ELSIF L_Source_Trust_Trend > REAL#1.0 THEN
        L_Source_Trust_Trend := REAL#1.0;
    END_IF;

    GVL_Heating_Source_Stability.G_State[L_i].Source_Trust_Trend :=
        L_Source_Trust_Trend;

    // ======================================================
    // TREND OBSERVATION
    // ======================================================
    GVL_Heating_Source_Stability.G_State[L_i].Degraded_Trend_Visible :=
        GVL_Heating_Circuit_Explainability.G_Source_Degraded[L_i] OR
        (GVL_Heating_Source_Stability.G_State[L_i].Fallback_Activation_Count >
         GVL_Heating_Source_Stability.G_State[L_i].Fallback_Recovery_Count);

    GVL_Heating_Source_Stability.G_State[L_i].Recovery_Trend_Visible :=
        (GVL_Heating_Source_Stability.G_State[L_i].Fallback_Recovery_Count > 0) AND
        (GVL_Heating_Source_Stability.G_State[L_i].Fallback_Recovery_Count >=
         GVL_Heating_Source_Stability.G_State[L_i].Fallback_Activation_Count);

    GVL_Heating_Source_Stability.G_State[L_i].Oscillation_Detected :=
        (GVL_Heating_Source_Stability.G_State[L_i].Source_Switch_Count >= 3) OR
        ((GVL_Heating_Source_Stability.G_State[L_i].Fallback_Activation_Count >= 2) AND
         (GVL_Heating_Source_Stability.G_State[L_i].Fallback_Recovery_Count >= 2));

    // ======================================================
    // INSTABILITY SCORE
    //
    // Intentionally simplified.
    // Predictive observability should remain explainable and deterministic.
    // ======================================================
    L_Instability_Score := REAL#0.0;

    IF GVL_Heating_Source_Stability.G_State[L_i].Oscillation_Detected THEN
        L_Instability_Score := L_Instability_Score + REAL#40.0;
    END_IF;

    IF GVL_Heating_Source_Stability.G_State[L_i].Degraded_Trend_Visible THEN
        L_Instability_Score := L_Instability_Score + REAL#30.0;
    END_IF;

    IF GVL_Heating_Source_Stability.G_State[L_i].Source_Loss_Count > 0 THEN
        L_Instability_Score := L_Instability_Score + REAL#30.0;
    END_IF;

    L_Instability_Score :=
        L_Instability_Score +
        (GVL_Heating_Source_Stability.G_State[L_i].Confidence_Volatility * REAL#20.0);

    IF L_Instability_Score > REAL#100.0 THEN
        L_Instability_Score := REAL#100.0;
    END_IF;

    GVL_Heating_Source_Stability.G_State[L_i].Instability_Score :=
        L_Instability_Score;

    GVL_Heating_Source_Stability.G_State[L_i].Instability_Attention :=
        L_Instability_Score >= REAL#60.0;

    // ======================================================
    // EXPLAINABILITY PUBLICATION
    // ======================================================
    IF GVL_Heating_Source_Stability.G_State[L_i].Source_Loss_Count > 0 THEN
        GVL_Heating_Source_Stability.G_State[L_i].Status_Code := 904;
        GVL_Heating_Source_Stability.G_State[L_i].Status_Text :=
            'Predictive source instability: source loss observed';

    ELSIF GVL_Heating_Source_Stability.G_State[L_i].Oscillation_Detected THEN
        GVL_Heating_Source_Stability.G_State[L_i].Status_Code := 903;
        GVL_Heating_Source_Stability.G_State[L_i].Status_Text :=
            'Predictive source instability: oscillation detected';

    ELSIF GVL_Heating_Source_Stability.G_State[L_i].Degraded_Trend_Visible THEN
        GVL_Heating_Source_Stability.G_State[L_i].Status_Code := 902;
        GVL_Heating_Source_Stability.G_State[L_i].Status_Text :=
            'Predictive source degradation trend observed';

    ELSE
        GVL_Heating_Source_Stability.G_State[L_i].Status_Code := 901;
        GVL_Heating_Source_Stability.G_State[L_i].Status_Text :=
            'Source stability nominal';
    END_IF;

    L_Last_Confidence[L_i] :=
        GVL_Heating_Circuit_Explainability.G_Selected_Source_Confidence[L_i];
END_FOR;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Source_Stability_Observer <<<
