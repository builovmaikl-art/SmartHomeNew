PROGRAM PRG_HMI_Dashboard
VAR
    L_i : INT;
END_VAR

// Confidence
GVL_HMI.G_HMI_Heating_Confidence := GVL_STATE.G_Heating_Confidence;
GVL_HMI.G_HMI_Heating_Confidence_Percent := REAL_TO_INT(GVL_STATE.G_Heating_Confidence * 100.0);

// Reason
GVL_HMI.G_HMI_Heating_Reason_Code := GVL_STATE.G_Heating_Confidence_Reason_Code;
GVL_HMI.G_HMI_Heating_Status_Text := GVL_STATE.G_Heating_Confidence_Reason_Text;

// Level
IF GVL_STATE.G_Heating_Confidence > 0.8 THEN
    GVL_HMI.G_HMI_Heating_Status_Level := 0;
ELSIF GVL_STATE.G_Heating_Confidence > 0.5 THEN
    GVL_HMI.G_HMI_Heating_Status_Level := 1;
ELSE
    GVL_HMI.G_HMI_Heating_Status_Level := 2;
END_IF;

// Predictive flags
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    GVL_HMI.G_HMI_Heating_Predictive_Pressure_Drop[L_i] := GVL_STATE.G_Predictive_Pump_Pressure_Drop[L_i];
    GVL_HMI.G_HMI_Heating_Predictive_Current_Rise[L_i] := GVL_STATE.G_Predictive_Pump_Current_Rise[L_i];
END_FOR;

END_PROGRAM
