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
    L_Instability_Score : REAL;
    L_Confidence_Delta : REAL;
    L_Confidence_Volatility : REAL;
    L_Source_Trust_Trend : REAL;
END_VAR

IF NOT VI_Enable THEN
    RETURN;
END_IF;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
    GVL_Heating_Source_Stability.G_Stability_Visible[L_i] := TRUE;

    // ======================================================
    // EDGE COUNTING
    // ======================================================
    IF GVL_Heating_Circuit_Explainability.G_Source_Switched_Event[L_i] THEN
        IF GVL_Heating_Source_Stability.G_Source_Switch_Count[L_i] < 65535 THEN
            GVL_Heating_Source_Stability.G_Source_Switch_Count[L_i] :=
                GVL_Heating_Source_Stability.G_Source_Switch_Count[L_i] + 1;
        END_IF;

        GVL_Heating_Source_Stability.G_Last_Observation_MS[L_i] := VI_System_Time_MS;
    END_IF;

    IF GVL_Heating_Circuit_Explainability.G_Fallback_Activated_Event[L_i] THEN
        IF GVL_Heating_Source_Stability.G_Fallback_Activation_Count[L_i] < 65535 THEN
            GVL_Heating_Source_Stability.G_Fallback_Activation_Count[L_i] :=
                GVL_Heating_Source_Stability.G_Fallback_Activation_Count[L_i] + 1;
        END_IF;

        GVL_Heating_Source_Stability.G_Last_Observation_MS[L_i] := VI_System_Time_MS;
    END_IF;

    IF GVL_Heating_Circuit_Explainability.G_Fallback_Recovered_Event[L_i] THEN
        IF GVL_Heating_Source_Stability.G_Fallback_Recovery_Count[L_i] < 65535 THEN
            GVL_Heating_Source_Stability.G_Fallback_Recovery_Count[L_i] :=
                GVL_Heating_Source_Stability.G_Fallback_Recovery_Count[L_i] + 1;
        END_IF;

        GVL_Heating_Source_Stability.G_Last_Observation_MS[L_i] := VI_System_Time_MS;
    END_IF;

    IF GVL_Heating_Circuit_Explainability.G_Source_Loss_Event[L_i] THEN
        IF GVL_Heating_Source_Stability.G_Source_Loss_Count[L_i] < 65535 THEN
            GVL_Heating_Source_Stability.G_Source_Loss_Count[L_i] :=
                GVL_Heating_Source_Stability.G_Source_Loss_Count[L_i] + 1;
        END_IF;

        GVL_Heating_Source_Stability.G_Last_Observation_MS[L_i] := VI_System_Time_MS;
    END_IF;

    // ======================================================
    // CONFIDENCE VOLATILITY
    // ======================================================
    L_Confidence_Delta := ABS(
        GVL_Heating_Circuit_Explainability.G_Selected_Source_Confidence[L_i] -
        L_Last_Confidence[L_i]
    );

    L_Confidence_Volatility :=
        GVL_Heating_Source_Stability.G_Confidence_Volatility[L_i] * REAL#0.90 +
        L_Confidence_Delta * REAL#0.10;

    IF L_Confidence_Volatility < REAL#0.0 THEN
        L_Confidence_Volatility := REAL#0.0;
    ELSIF L_Confidence_Volatility > REAL#1.0 THEN
        L_Confidence_Volatility := REAL#1.0;
    END_IF;

    GVL_Heating_Source_Stability.G_Confidence_Volatility[L_i] :=
        L_Confidence_Volatility;

    // ======================================================
    // SOURCE TRUST TREND
    // ======================================================
    L_Source_Trust_Trend :=
        GVL_Heating_Source_Stability.G_Source_Trust_Trend[L_i] * REAL#0.95 +
        GVL_Heating_Circuit_Explainability.G_Selected_Source_Confidence[L_i] * REAL#0.05;

    IF GVL_Heating_Circuit_Explainability.G_Source_Degraded[L_i] THEN
        L_Source_Trust_Trend := L_Source_Trust_Trend * REAL#0.98;
    END_IF;

    IF L_Source_Trust_Trend < REAL#0.0 THEN
        L_Source_Trust_Trend := REAL#0.0;
    ELSIF L_Source_Trust_Trend > REAL#1.0 THEN
        L_Source_Trust_Trend := REAL#1.0;
    END_IF;

    GVL_Heating_Source_Stability.G_Source_Trust_Trend[L_i] :=
        L_Source_Trust_Trend;

    // ======================================================
    // TREND OBSERVATION
    // ======================================================
    GVL_Heating_Source_Stability.G_Degraded_Trend_Visible[L_i] :=
        GVL_Heating_Circuit_Explainability.G_Source_Degraded[L_i] OR
        (GVL_Heating_Source_Stability.G_Fallback_Activation_Count[L_i] >
         GVL_Heating_Source_Stability.G_Fallback_Recovery_Count[L_i]);

    GVL_Heating_Source_Stability.G_Recovery_Trend_Visible[L_i] :=
        (GVL_Heating_Source_Stability.G_Fallback_Recovery_Count[L_i] > 0) AND
        (GVL_Heating_Source_Stability.G_Fallback_Recovery_Count[L_i] >=
         GVL_Heating_Source_Stability.G_Fallback_Activation_Count[L_i]);

    GVL_Heating_Source_Stability.G_Oscillation_Detected[L_i] :=
        (GVL_Heating_Source_Stability.G_Source_Switch_Count[L_i] >= 3) OR
        ((GVL_Heating_Source_Stability.G_Fallback_Activation_Count[L_i] >= 2) AND
         (GVL_Heating_Source_Stability.G_Fallback_Recovery_Count[L_i] >= 2));

    // ======================================================
    // INSTABILITY SCORE
    // ======================================================
    L_Instability_Score :=
        REAL(GVL_Heating_Source_Stability.G_Source_Switch_Count[L_i]) * REAL#5.0 +
        REAL(GVL_Heating_Source_Stability.G_Fallback_Activation_Count[L_i]) * REAL#10.0 +
        REAL(GVL_Heating_Source_Stability.G_Source_Loss_Count[L_i]) * REAL#25.0 +
        L_Confidence_Volatility * REAL#50.0;

    IF GVL_Heating_Source_Stability.G_Oscillation_Detected[L_i] THEN
        L_Instability_Score := L_Instability_Score + REAL#20.0;
    END_IF;

    IF L_Instability_Score > REAL#100.0 THEN
        L_Instability_Score := REAL#100.0;
    END_IF;

    GVL_Heating_Source_Stability.G_Instability_Score[L_i] :=
        L_Instability_Score;

    GVL_Heating_Source_Stability.G_Instability_Attention[L_i] :=
        L_Instability_Score >= REAL#60.0;

    // ======================================================
    // EXPLAINABILITY PUBLICATION
    // ======================================================
    IF GVL_Heating_Source_Stability.G_Source_Loss_Count[L_i] > 0 THEN
        GVL_Heating_Source_Stability.G_Status_Code[L_i] := 904;
        GVL_Heating_Source_Stability.G_Status_Text[L_i] :=
            'Predictive source instability: repeated source loss observed';

    ELSIF GVL_Heating_Source_Stability.G_Oscillation_Detected[L_i] THEN
        GVL_Heating_Source_Stability.G_Status_Code[L_i] := 903;
        GVL_Heating_Source_Stability.G_Status_Text[L_i] :=
            'Predictive source instability: oscillation detected';

    ELSIF GVL_Heating_Source_Stability.G_Degraded_Trend_Visible[L_i] THEN
        GVL_Heating_Source_Stability.G_Status_Code[L_i] := 902;
        GVL_Heating_Source_Stability.G_Status_Text[L_i] :=
            'Predictive source degradation trend observed';

    ELSE
        GVL_Heating_Source_Stability.G_Status_Code[L_i] := 901;
        GVL_Heating_Source_Stability.G_Status_Text[L_i] :=
            'Source stability nominal';
    END_IF;

    L_Last_Confidence[L_i] :=
        GVL_Heating_Circuit_Explainability.G_Selected_Source_Confidence[L_i];
END_FOR;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Source_Stability_Observer <<<
