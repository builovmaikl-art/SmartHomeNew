// ==============================================================================
// Heating circuit explainability adapter
//
// Projection-to-explainability adapter.
//
// DOES NOT own runtime authority.
// DOES NOT own outputs.
// DOES NOT close valves.
// DOES NOT modify heating demand.
// DOES NOT override runtime decisions.
//
// Reads canonical runtime projection contracts and publishes legacy-compatible
// circuit explainability surfaces for HMI/diagnostics/supervisory visibility.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Circuit_Explainability_Adapter
VAR_INPUT
    VI_Enable : BOOL;
END_VAR

VAR
    L_i : INT;
END_VAR

IF NOT VI_Enable THEN
    RETURN;
END_IF;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
    GVL_Heating_Circuit_Explainability.G_Source_Selection_Visible[L_i] :=
        GVL_Heating_Runtime_Projection.G_Circuit_Projection[L_i].Visible;

    GVL_Heating_Circuit_Explainability.G_Selected_Source_Code[L_i] :=
        GVL_Heating_Runtime_Projection.G_Circuit_Projection[L_i].Selected_Source_Code;

    CASE GVL_Heating_Runtime_Projection.G_Circuit_Projection[L_i].Selected_Source_Code OF
        1:
            GVL_Heating_Circuit_Explainability.G_Selected_Source_Text[L_i] := 'room';
        2:
            GVL_Heating_Circuit_Explainability.G_Selected_Source_Text[L_i] := 'floor';
    ELSE
        GVL_Heating_Circuit_Explainability.G_Selected_Source_Text[L_i] := 'none';
    END_CASE;

    GVL_Heating_Circuit_Explainability.G_Fallback_Active[L_i] :=
        GVL_Heating_Runtime_Projection.G_Circuit_Projection[L_i].Fallback_Active;

    GVL_Heating_Circuit_Explainability.G_Source_Degraded[L_i] :=
        GVL_Heating_Runtime_Projection.G_Circuit_Projection[L_i].Source_Degraded;

    GVL_Heating_Circuit_Explainability.G_Selected_Source_Confidence[L_i] :=
        GVL_Heating_Runtime_Projection.G_Circuit_Projection[L_i].Selected_Source_Confidence;

    // Primary/fallback confidence remain legacy-compatible fields. The runtime
    // projection intentionally exposes selected confidence only, so these fields
    // mirror the selected source confidence until a dedicated richer projection
    // contract is introduced.
    GVL_Heating_Circuit_Explainability.G_Primary_Source_Confidence[L_i] :=
        GVL_Heating_Runtime_Projection.G_Circuit_Projection[L_i].Selected_Source_Confidence;

    GVL_Heating_Circuit_Explainability.G_Fallback_Source_Confidence[L_i] :=
        GVL_Heating_Runtime_Projection.G_Circuit_Projection[L_i].Selected_Source_Confidence;

    GVL_Heating_Circuit_Explainability.G_Reason_Code[L_i] :=
        GVL_Heating_Runtime_Projection.G_Circuit_Projection[L_i].Reason_Code;

    GVL_Heating_Circuit_Explainability.G_Reason_Text[L_i] :=
        GVL_Heating_Runtime_Projection.G_Circuit_Projection[L_i].Reason_Text;

    GVL_Heating_Circuit_Explainability.G_Source_Switched_Event[L_i] :=
        GVL_Heating_Runtime_Projection.G_Circuit_Projection[L_i].Source_Switched_Event;

    GVL_Heating_Circuit_Explainability.G_Fallback_Activated_Event[L_i] :=
        GVL_Heating_Runtime_Projection.G_Circuit_Projection[L_i].Fallback_Activated_Event;

    GVL_Heating_Circuit_Explainability.G_Fallback_Recovered_Event[L_i] :=
        GVL_Heating_Runtime_Projection.G_Circuit_Projection[L_i].Fallback_Recovered_Event;

    GVL_Heating_Circuit_Explainability.G_Source_Loss_Event[L_i] :=
        GVL_Heating_Runtime_Projection.G_Circuit_Projection[L_i].Source_Loss_Event;

    GVL_Heating_Circuit_Explainability.G_Last_Event_MS[L_i] :=
        GVL_Heating_Runtime_Projection.G_Circuit_Projection[L_i].Last_Event_MS;

    GVL_Heating_Circuit_Explainability.G_Last_Event_Code[L_i] :=
        GVL_Heating_Runtime_Projection.G_Circuit_Projection[L_i].Last_Event_Code;

    GVL_Heating_Circuit_Explainability.G_Last_Event_Text[L_i] :=
        GVL_Heating_Runtime_Projection.G_Circuit_Projection[L_i].Last_Event_Text;
END_FOR;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Circuit_Explainability_Adapter <<<
