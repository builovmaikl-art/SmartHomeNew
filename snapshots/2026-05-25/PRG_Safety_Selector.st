PROGRAM PRG_Safety_Selector
VAR
    L_i : INT;
END_VAR

GVL_Safety_Selector.G_CO_Effective := 0.0;
GVL_Safety_Selector.G_Methane_Effective := 0.0;
GVL_Safety_Selector.G_Smoke_Effective := FALSE;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_CO_SENSORS DO
    GVL_Safety_Selector.G_CO_Effective_Array[L_i] := GVL_STATE.G_CO_Sensors[L_i];
    IF GVL_STATE.G_CO_Sensors[L_i] > GVL_Safety_Selector.G_CO_Effective THEN
        GVL_Safety_Selector.G_CO_Effective := GVL_STATE.G_CO_Sensors[L_i];
    END_IF;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_METHANE_SENSORS DO
    GVL_Safety_Selector.G_Methane_Effective_Array[L_i] := GVL_STATE.G_Methane_Sensors[L_i];
    IF GVL_STATE.G_Methane_Sensors[L_i] > GVL_Safety_Selector.G_Methane_Effective THEN
        GVL_Safety_Selector.G_Methane_Effective := GVL_STATE.G_Methane_Sensors[L_i];
    END_IF;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SMOKE_SENSORS DO
    GVL_Safety_Selector.G_Smoke_Effective_Array[L_i] := GVL_STATE.G_Smoke_Sensors[L_i];
    GVL_Safety_Selector.G_Smoke_Effective :=
        GVL_Safety_Selector.G_Smoke_Effective
        OR GVL_STATE.G_Smoke_Sensors[L_i];
END_FOR;

// >>> BULK_SYNC_ANCHOR: PRG_Safety_Selector <<<
END_PROGRAM
