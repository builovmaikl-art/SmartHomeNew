FUNCTION_BLOCK FB_Heating_Policy_Manager
VAR_INPUT
    VI_System_Mode : E_System_Operating_Mode;
    VI_RootCause : E_Heating_RootCause;
    VI_Emergency_Stop : BOOL;
    VI_Gas_Safety : BOOL;
END_VAR

VAR_OUTPUT
    VO_Policy_Mode : E_Heating_Policy_Mode;
    VO_Block_Heating : BOOL;
END_VAR

// --- Policy resolution ---

// Safety has absolute priority
IF VI_Emergency_Stop OR VI_Gas_Safety THEN
    VO_Policy_Mode := E_Heating_Policy_Mode.HPM_SAFETY_BLOCK;
    VO_Block_Heating := TRUE;
    RETURN;
END_IF;

// Root cause driven policy
CASE VI_RootCause OF

    E_Heating_RootCause.RC_IO_OFFLINE:
        VO_Policy_Mode := E_Heating_Policy_Mode.HPM_DEGRADED;
        VO_Block_Heating := TRUE;
        RETURN;

    E_Heating_RootCause.RC_PUMP_FAILURE,
    E_Heating_RootCause.RC_VALVES_CLOSED:
        VO_Policy_Mode := E_Heating_Policy_Mode.HPM_FAULT_ISOLATION;
        VO_Block_Heating := FALSE; // allow partial
        RETURN;

    E_Heating_RootCause.RC_NO_FLAME,
    E_Heating_RootCause.RC_BOILER_ERROR:
        VO_Policy_Mode := E_Heating_Policy_Mode.HPM_DEGRADED;
        VO_Block_Heating := FALSE;
        RETURN;

END_CASE;

// System mode fallback
IF VI_System_Mode = E_System_Operating_Mode.MODE_DEGRADED THEN
    VO_Policy_Mode := E_Heating_Policy_Mode.HPM_DEGRADED;
    VO_Block_Heating := FALSE;
ELSE
    VO_Policy_Mode := E_Heating_Policy_Mode.HPM_NORMAL;
    VO_Block_Heating := FALSE;
END_IF;

END_FUNCTION_BLOCK
