// ==============================================================================
// Heating root-cause diagnostics observer
// Pure diagnostics/explainability layer.
// Does NOT own control/runtime decisions.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_RootCause_Diagnostics
VAR_INPUT
    VI_Enable : BOOL;
END_VAR
VAR
    L_RootCause : E_Heating_RootCause;
    L_Confidence : REAL;
    L_Confidence_Text : STRING(128);
    L_Confidence_Code : INT;
END_VAR

// ======================================================
// DEFAULTS
// ======================================================
L_RootCause := E_Heating_RootCause.RC_NONE;
L_Confidence := 1.0;
L_Confidence_Text := 'Heating operating normally';
L_Confidence_Code := 0;

IF NOT VI_Enable THEN
    GVL_STATE.G_Heating_RootCause := E_Heating_RootCause.RC_NONE;
    GVL_STATE.G_Heating_RootConfidence := 0.0;
    GVL_STATE.G_Heating_Confidence := 0.0;
    GVL_STATE.G_Heating_Error_Score := 1.0;
    GVL_STATE.G_Heating_Confidence_Reason_Code := -1;
    GVL_STATE.G_Heating_Confidence_Reason_Text := 'Heating diagnostics disabled';
    RETURN;
END_IF;

// ======================================================
// ROOT CAUSE PRIORITY TREE
// ======================================================
IF GVL_STATE.G_Safety_Emergency_Stop THEN

    L_RootCause := E_Heating_RootCause.RC_EMERGENCY_STOP;
    L_Confidence := 0.01;
    L_Confidence_Text := 'Heating blocked by emergency stop';
    L_Confidence_Code := 10;

ELSIF GVL_STATE.G_Safety_Gas_Latched THEN

    L_RootCause := E_Heating_RootCause.RC_GAS_SAFETY;
    L_Confidence := 0.01;
    L_Confidence_Text := 'Heating blocked by gas safety latch';
    L_Confidence_Code := 20;

ELSIF GVL_STATE.G_Heating_IO_Fault THEN

    L_RootCause := E_Heating_RootCause.RC_IO_OFFLINE;
    L_Confidence := 0.10;
    L_Confidence_Text := 'Heating IO fault active';
    L_Confidence_Code := 30;

ELSIF NOT GVL_STATE.G_Heating_Cascade_Available THEN

    L_RootCause := E_Heating_RootCause.RC_BOILER_OFFLINE;
    L_Confidence := 0.05;
    L_Confidence_Text := 'Heating cascade unavailable';
    L_Confidence_Code := 100;

ELSIF GVL_STATE.G_Heating_Cascade_Transport_Degraded THEN

    L_RootCause := E_Heating_RootCause.RC_IO_OFFLINE;
    L_Confidence := 0.25;
    L_Confidence_Text := 'OpenTherm transport degraded';
    L_Confidence_Code := 200;

ELSIF GVL_STATE.G_Heating_Cascade_Ignition_Timeout THEN

    L_RootCause := E_Heating_RootCause.RC_NO_FLAME;
    L_Confidence := 0.20;
    L_Confidence_Text := 'Boiler ignition timeout detected';
    L_Confidence_Code := 300;

ELSIF GVL_STATE.G_Heating_Cascade_No_Flame THEN

    L_RootCause := E_Heating_RootCause.RC_NO_FLAME;
    L_Confidence := 0.35;
    L_Confidence_Text := 'Cascade active but flame missing';
    L_Confidence_Code := 400;

ELSIF GVL_STATE.G_Heating_Sensor_Fault THEN

    L_RootCause := E_Heating_RootCause.RC_SENSOR_ERROR;
    L_Confidence := 0.40;
    L_Confidence_Text := 'Heating sensor fault active';
    L_Confidence_Code := 450;

ELSIF GVL_STATE.G_Heating_Cascade_Partial_Capacity THEN

    L_RootCause := E_Heating_RootCause.RC_LOW_SUPPLY_TEMP;
    L_Confidence := 0.60;
    L_Confidence_Text := 'Partial cascade capacity available';
    L_Confidence_Code := 500;

ELSIF GVL_STATE.G_Heating_Subsystem_Degraded THEN

    L_RootCause := E_Heating_RootCause.RC_UNKNOWN;
    L_Confidence := 0.70;
    L_Confidence_Text := 'Heating subsystem degraded';
    L_Confidence_Code := 600;

ELSE

    L_RootCause := E_Heating_RootCause.RC_NONE;
    L_Confidence := 1.0;
    L_Confidence_Text := 'Heating operating normally';
    L_Confidence_Code := 0;

END_IF;

// ======================================================
// PUBLISH DIAGNOSTICS STATE
// ======================================================
GVL_STATE.G_Heating_RootCause := L_RootCause;
GVL_STATE.G_Heating_RootConfidence := L_Confidence;
GVL_STATE.G_Heating_Confidence := L_Confidence;
GVL_STATE.G_Heating_Error_Score := 1.0 - L_Confidence;
GVL_STATE.G_Heating_Confidence_Reason_Code := L_Confidence_Code;
GVL_STATE.G_Heating_Confidence_Reason_Text := L_Confidence_Text;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_RootCause_Diagnostics <<<
