FUNCTION_BLOCK FB_Heating_Policy_Manager
VAR_INPUT
    VI_System_Time_MS : UDINT;
    VI_System_Mode : E_System_Operating_Mode;
    VI_RootCause : E_Heating_RootCause;
    VI_RootConfidence : REAL;
    VI_Min_Hold_MS : UDINT;
    VI_Emergency_Stop : BOOL;
    VI_Gas_Safety : BOOL;
END_VAR

VAR_OUTPUT
    VO_Policy_Mode : E_Heating_Policy_Mode;
    VO_Block_Heating : BOOL;
    VO_Target_Adjustment : REAL;
    VO_Priority_Multiplier : REAL;
END_VAR

VAR
    L_Raw_Mode : E_Heating_Policy_Mode;
    L_Raw_Block : BOOL;
    L_Raw_Target_Adjustment : REAL;
    L_Raw_Priority_Multiplier : REAL;
    L_Held_Mode : E_Heating_Policy_Mode;
    L_Held_Block : BOOL;
    L_Held_Target_Adjustment : REAL;
    L_Held_Priority_Multiplier : REAL;
    L_Last_Accept_MS : UDINT;
    L_Initialized : BOOL;
    L_Effective_Hold_MS : UDINT;
    L_Force_Immediate : BOOL;
END_VAR

L_Raw_Mode := E_Heating_Policy_Mode.HPM_NORMAL;
L_Raw_Block := FALSE;
L_Raw_Target_Adjustment := 0.0;
L_Raw_Priority_Multiplier := 1.0;
L_Force_Immediate := FALSE;

L_Effective_Hold_MS := VI_Min_Hold_MS;
IF VI_RootConfidence >= 0.9 THEN
    L_Effective_Hold_MS := VI_Min_Hold_MS / 2;
END_IF;

IF VI_Emergency_Stop OR VI_Gas_Safety THEN
    L_Raw_Mode := E_Heating_Policy_Mode.HPM_SAFETY_BLOCK;
    L_Raw_Block := TRUE;
    L_Force_Immediate := TRUE;

ELSIF VI_RootCause = E_Heating_RootCause.RC_IO_OFFLINE THEN
    L_Raw_Mode := E_Heating_Policy_Mode.HPM_DEGRADED;
    L_Raw_Block := TRUE;
    L_Force_Immediate := TRUE;

ELSE
    IF VI_RootConfidence < 0.6 THEN
        IF VI_System_Mode = E_System_Operating_Mode.MODE_DEGRADED THEN
            L_Raw_Mode := E_Heating_Policy_Mode.HPM_DEGRADED;
        ELSE
            L_Raw_Mode := E_Heating_Policy_Mode.HPM_NORMAL;
        END_IF;
    ELSE
        CASE VI_RootCause OF

            E_Heating_RootCause.RC_PUMP_FAILURE:
                L_Raw_Mode := E_Heating_Policy_Mode.HPM_FAULT_ISOLATION;
                L_Raw_Priority_Multiplier := 0.5;

            E_Heating_RootCause.RC_VALVES_CLOSED:
                L_Raw_Mode := E_Heating_Policy_Mode.HPM_FAULT_ISOLATION;
                L_Raw_Target_Adjustment := -2.0;

            E_Heating_RootCause.RC_NO_HEAT_TRANSFER:
                L_Raw_Mode := E_Heating_Policy_Mode.HPM_DEGRADED;
                L_Raw_Target_Adjustment := 3.0;

            E_Heating_RootCause.RC_NO_FLAME,
            E_Heating_RootCause.RC_BOILER_ERROR:
                L_Raw_Mode := E_Heating_Policy_Mode.HPM_DEGRADED;
                L_Raw_Priority_Multiplier := 0.7;

            ELSE
                IF VI_System_Mode = E_System_Operating_Mode.MODE_DEGRADED THEN
                    L_Raw_Mode := E_Heating_Policy_Mode.HPM_DEGRADED;
                ELSE
                    L_Raw_Mode := E_Heating_Policy_Mode.HPM_NORMAL;
                END_IF;

        END_CASE;
    END_IF;
END_IF;

IF NOT L_Initialized THEN
    L_Held_Mode := L_Raw_Mode;
    L_Held_Block := L_Raw_Block;
    L_Held_Target_Adjustment := L_Raw_Target_Adjustment;
    L_Held_Priority_Multiplier := L_Raw_Priority_Multiplier;
    L_Last_Accept_MS := VI_System_Time_MS;
    L_Initialized := TRUE;

ELSIF L_Force_Immediate THEN
    L_Held_Mode := L_Raw_Mode;
    L_Held_Block := L_Raw_Block;
    L_Held_Target_Adjustment := L_Raw_Target_Adjustment;
    L_Held_Priority_Multiplier := L_Raw_Priority_Multiplier;
    L_Last_Accept_MS := VI_System_Time_MS;

ELSIF (L_Raw_Mode <> L_Held_Mode)
   OR (ABS(L_Raw_Target_Adjustment - L_Held_Target_Adjustment) > 0.001)
   OR (ABS(L_Raw_Priority_Multiplier - L_Held_Priority_Multiplier) > 0.001)
   OR (L_Raw_Block <> L_Held_Block) THEN

    IF (VI_System_Time_MS - L_Last_Accept_MS) >= L_Effective_Hold_MS THEN
        L_Held_Mode := L_Raw_Mode;
        L_Held_Block := L_Raw_Block;
        L_Held_Target_Adjustment := L_Raw_Target_Adjustment;
        L_Held_Priority_Multiplier := L_Raw_Priority_Multiplier;
        L_Last_Accept_MS := VI_System_Time_MS;
    END_IF;
END_IF;

VO_Policy_Mode := L_Held_Mode;
VO_Block_Heating := L_Held_Block;
VO_Target_Adjustment := L_Held_Target_Adjustment;
VO_Priority_Multiplier := L_Held_Priority_Multiplier;

END_FUNCTION_BLOCK
